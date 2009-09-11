//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "YfrogPhotoService.h"
#import "YfrogResponseParser.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "NSError+InstantiationAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "YfrogCredentials+KeychainAdditions.h"
#import "InfoPlistConfigReader.h"

@interface YfrogPhotoService ()

@property (nonatomic, copy) NSString * yfrogUrl;

@property (nonatomic, retain) NSMutableData * data;
@property (nonatomic, retain) NSURLConnection * connection;

@property (nonatomic, retain) YfrogResponseParser * parser;

+ (NSURLRequest *)requestForPostingImage:(UIImage *)image
                                   toUrl:(NSURL *)url
                            withUsername:(NSString *)username
                                password:(NSString *)password;
+ (NSURLRequest *)requestForPostingData:(NSData *)data
                             ofMimeType:(NSString *)mimeType
                                  toUrl:(NSURL *)url
                           withUsername:(NSString *)username
                               password:(NSString *)password;

@end

@implementation YfrogPhotoService

@synthesize yfrogUrl;
@synthesize data, connection;
@synthesize parser;

- (void)dealloc
{
    self.yfrogUrl = nil;
    self.connection = nil;
    self.data = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.yfrogUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"YfrogPostUrl"];
        parser = [[YfrogResponseParser alloc] init];
    }

    return self;
}

#pragma mark Public Implementation

- (void)sendData:(NSData *)sendableData
      ofMimeType:(NSString *)mimeType
 withCredentials:(YfrogCredentials *)someCredentials
{
    NSURL * url = [NSURL URLWithString:self.yfrogUrl];
    NSURLRequest * request =
        [[self class] requestForPostingData:sendableData
                                 ofMimeType:mimeType
                                      toUrl:url
                               withUsername:someCredentials.username
                                   password:someCredentials.password];

    self.connection =
        [[[NSURLConnection alloc] initWithRequest:request
                                         delegate:self
                                 startImmediately:YES] autorelease];

    self.data = [NSMutableData data];

    // HACK
    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(YfrogCredentials *)ctls
{
    [super sendImage:anImage withCredentials:ctls];

    NSData * imageData = UIImagePNGRepresentation(image);
    [self sendData:imageData ofMimeType:@"image/png" withCredentials:ctls];
}

- (void)sendVideoAtUrl:(NSURL *)url
  withCredentials:(YfrogCredentials *)ctls
{
    [super sendVideoAtUrl:url withCredentials:ctls];

    NSData * video = [NSData dataWithContentsOfURL:url];
    [self sendData:video ofMimeType:@"video/quicktime" withCredentials:ctls];
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)fragment
{
    [data appendData:fragment];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    NSLog(@"Received response from Yfrog: '%@'.", [[[NSString alloc]
           initWithData:data encoding:4] autorelease]);

    [self.parser parse:data];

    if (self.parser.error) {
        NSError * error =
            [NSError errorWithLocalizedDescription:self.parser.error];
        [self.delegate service:self failedToPostImage:error];
    } else
        if (self.image)
            [self.delegate service:self didPostImageToUrl:self.parser.mediaUrl];
        else if (self.videoUrl)
            [self.delegate service:self didPostVideoToUrl:self.parser.mediaUrl];

    // HACK
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    if (self.image)
        [self.delegate service:self failedToPostImage:error];
    else if (self.videoUrl)
        [self.delegate service:self failedToPostVideo:error];

    // HACK
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

#pragma mark Helpers for building the post body

+ (NSURLRequest *)requestForPostingImage:(UIImage *)image
                                   toUrl:(NSURL *)url
                            withUsername:(NSString *)username
                                password:(NSString *)password
{
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:url];
    [postRequest setHTTPMethod:@"POST"];

    NSString * stringBoundary = @"0xKhTmLbOuNdArY";
    NSString * contentType = [NSString 
        stringWithFormat:@"multipart/form-data; boundary=%@",
        stringBoundary];
    [postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSMutableData * postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n\r\n--%@\r\n", 
                stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
       @"Content-Disposition: form-data; name=\"source\"\r\n\r\n"] 
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:@"Twitbit for iPhone"] 
       dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", 
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"username\"\r\n\r\n"]
   dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"password\"\r\n\r\n"] 
   dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];

    NSString * mimeType = @"image/png";

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"media\"; filename=\"file\"\r\n"]
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:
          @"Content-Type: %@\r\n", mimeType] 
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
            @"Content-Transfer-Encoding: binary\r\n\r\n"] 
                      dataUsingEncoding:NSUTF8StringEncoding]];

    NSData * imageData = [self dataForImageUsingCompressionSettings:image];
    [postBody appendData:imageData];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [postRequest setHTTPBody:postBody];

    return postRequest;
}

+ (NSURLRequest *)requestForPostingVideo:(NSData *)video
                                   toUrl:(NSURL *)url
                            withUsername:(NSString *)username
                                password:(NSString *)password
{
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:url];
    [postRequest setHTTPMethod:@"POST"];

    NSString * stringBoundary = @"0xKhTmLbOuNdArY";
    NSString * contentType = [NSString 
        stringWithFormat:@"multipart/form-data; boundary=%@",
        stringBoundary];
    [postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSMutableData * postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n\r\n--%@\r\n", 
                stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
       @"Content-Disposition: form-data; name=\"source\"\r\n\r\n"] 
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:@"Twitbit for iPhone"] 
       dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", 
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"username\"\r\n\r\n"]
   dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"password\"\r\n\r\n"] 
   dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];

    NSString * mimeType = @"video/quicktime";

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"media\"; filename=\"file\"\r\n"]
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:
          @"Content-Type: %@\r\n", mimeType] 
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
            @"Content-Transfer-Encoding: binary\r\n\r\n"] 
                      dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:video];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [postRequest setHTTPBody:postBody];

    return postRequest;
}

+ (NSURLRequest *)requestForPostingData:(NSData *)data
                             ofMimeType:(NSString *)mimeType
                                  toUrl:(NSURL *)url
                           withUsername:(NSString *)username
                               password:(NSString *)password
{
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:url];
    [postRequest setHTTPMethod:@"POST"];

    NSString * stringBoundary = @"0xKhTmLbOuNdArY";
    NSString * contentType = [NSString 
        stringWithFormat:@"multipart/form-data; boundary=%@",
        stringBoundary];
    [postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSMutableData * postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n\r\n--%@\r\n", 
                stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
       @"Content-Disposition: form-data; name=\"source\"\r\n\r\n"] 
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:@"Twitbit for iPhone"] 
       dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", 
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"username\"\r\n\r\n"]
   dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"password\"\r\n\r\n"] 
   dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
   @"Content-Disposition: form-data; name=\"media\"; filename=\"file\"\r\n"]
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:
          @"Content-Type: %@\r\n", mimeType] 
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:
            @"Content-Transfer-Encoding: binary\r\n\r\n"] 
                      dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:data];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [postRequest setHTTPBody:postBody];

    return postRequest;
}

@end
