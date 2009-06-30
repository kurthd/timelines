//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicImageSender.h"
#import "TwitPicResponseParser.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "NSError+InstantiationAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TwitPicCredentials+KeychainAdditions.h"

@interface TwitPicImageSender ()

@property (nonatomic, copy) NSString * twitPicUrl;

@property (nonatomic, retain) UIImage * image;

@property (nonatomic, retain) NSMutableData * data;
@property (nonatomic, retain) NSURLConnection * connection;

@property (nonatomic, retain) TwitPicResponseParser * parser;

+ (NSURLRequest *)requestForPostingImage:(UIImage *)image
                                   toUrl:(NSURL *)url
                            withUsername:(NSString *)username
                                password:(NSString *)password;

@end

@implementation TwitPicImageSender

@synthesize delegate;
@synthesize twitPicUrl;
@synthesize image;
@synthesize data, connection;
@synthesize parser;

- (void)dealloc
{
    self.delegate = nil;
    self.twitPicUrl = nil;
    self.image = nil;
    self.connection = nil;
    self.data = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)initWithUrl:(NSString *)aUrl
{
    if (self = [super init])
        self.twitPicUrl = aUrl;

    return self;
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(TwitPicCredentials *)credentials
{
    self.image = anImage;

    NSURL * url = [NSURL URLWithString:self.twitPicUrl];
    NSURLRequest * request =
        [[self class] requestForPostingImage:self.image
                                       toUrl:url
                                withUsername:credentials.username
                                    password:credentials.password];

    self.connection =
        [[[NSURLConnection alloc] initWithRequest:request
                                         delegate:self
                                 startImmediately:YES] autorelease];

    self.data = [NSMutableData data];

    [[UIApplication sharedApplication] networkActivityIsStarting];
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
        [delegate sender:self failedToPostImage:error];
    } else
        [delegate sender:self didPostImageToUrl:self.parser.mediaUrl];

    // HACK
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    [delegate sender:self failedToPostImage:error];

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
    [postBody appendData:[[NSString stringWithString:@"twitch"] 
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

    NSData * imageData = UIImagePNGRepresentation(image);
    [postBody appendData:imageData];

    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",
            stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [postRequest setHTTPBody:postBody];

    return postRequest;
}

#pragma mark Accessors

- (TwitPicResponseParser *)parser
{
    if (!parser)
        parser = [[TwitPicResponseParser alloc] init];

    return parser;
}

@end