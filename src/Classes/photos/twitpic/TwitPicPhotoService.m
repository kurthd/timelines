//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicPhotoService.h"
#import "TwitPicResponseParser.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "NSError+InstantiationAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TwitPicCredentials+KeychainAdditions.h"
#import "InfoPlistConfigReader.h"

@interface TwitPicPhotoService ()

@property (nonatomic, copy) NSString * twitPicUrl;

@property (nonatomic, retain) NSMutableData * data;
@property (nonatomic, retain) NSURLConnection * connection;

@property (nonatomic, retain) TwitPicResponseParser * parser;

- (NSURLRequest *)requestForPostingImage:(NSData *)image
                                mimeType:(NSString *)mimeType
                                   toUrl:(NSURL *)url
                            withUsername:(NSString *)username
                                password:(NSString *)password;

@end

@implementation TwitPicPhotoService

@synthesize twitPicUrl;
@synthesize data, connection;
@synthesize parser;

- (void)dealloc
{
    self.twitPicUrl = nil;
    self.connection = nil;
    self.data = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.twitPicUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"TwitPicPostUrl"];
        parser = [[TwitPicResponseParser alloc] init];
    }

    return self;
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(TwitPicCredentials *)someCredentials
{
    [super sendImage:anImage withCredentials:someCredentials];

    NSData * imageData = [self dataForImageUsingCompressionSettings:anImage];
    NSString * mimeType = [self mimeTypeForImage:anImage];
    NSURL * url = [NSURL URLWithString:self.twitPicUrl];
    NSURLRequest * request =
        [self requestForPostingImage:imageData
                            mimeType:mimeType
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

- (void)sendVideo:(NSData *)aVideo
  withCredentials:(TwitPicCredentials *)ctls
{
    NSAssert(
        NO, @"Trying to send a video via TwitPic, which does not support it.");
}

- (void)cancelUpload
{
    [super cancelUpload];
    [self.connection cancel];
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)fragment
{
    [data appendData:fragment];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    NSLog(@"Received response from TwitPic: '%@'.", [[[NSString alloc]
           initWithData:data encoding:4] autorelease]);

    [self.parser parse:data];

    if (self.parser.error) {
        NSError * error =
            [NSError errorWithLocalizedDescription:self.parser.error];
        [self.delegate service:self failedToPostImage:error];
    } else
        [self.delegate service:self didPostImageToUrl:self.parser.mediaUrl];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    [self.delegate service:self failedToPostImage:error];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

#pragma mark Helpers for building the post body

- (NSURLRequest *)requestForPostingImage:(NSData *)imageData
                                mimeType:(NSString *)mimeType
                                   toUrl:(NSURL *)url
                            withUsername:(NSString *)username
                                password:(NSString *)password
{
    static NSString * devKey = @"023AGLTUc7533b166461ddb3bc523c54ab082240";

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
       @"Content-Disposition: form-data; name=\"key\"\r\n\r\n"] 
       dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithString:devKey] 
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

    [postBody appendData:imageData];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [postRequest setHTTPBody:postBody];

    return postRequest;
}

@end
