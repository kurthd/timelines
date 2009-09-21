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
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@interface TwitPicPhotoService ()

@property (nonatomic, copy) NSString * twitPicUrl;

@property (nonatomic, retain) ASIHTTPRequest * request;
@property (nonatomic, retain) ASINetworkQueue * queue;

@property (nonatomic, retain) TwitPicResponseParser * parser;

- (void)uploadData:(NSData *)data toUrl:(NSURL *)url;

+ (NSString *)devKey;

@end

@implementation TwitPicPhotoService

@synthesize twitPicUrl;
@synthesize request, queue;
@synthesize parser;

- (void)dealloc
{
    self.twitPicUrl = nil;
    self.request = nil;
    self.queue = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.twitPicUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"TwitPicPostUrl"];
        parser = [[TwitPicResponseParser alloc] init];
        queue = [[ASINetworkQueue alloc] init];
    }

    return self;
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(TwitPicCredentials *)someCredentials
{
    SEL selector = @selector(sendImageOnTimer:);
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        anImage, @"image",
        someCredentials, @"credentials",
        nil];

    // exit from here quickly so the modal view disappears
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:self
                                   selector:selector
                                   userInfo:userInfo
                                    repeats:NO];
}

- (void)sendImageOnTimer:(NSTimer *)timer
{
    NSDictionary * userInfo = timer.userInfo;
    UIImage * anImage = [userInfo objectForKey:@"image"];
    TwitPicCredentials * someCredentials =
        [userInfo objectForKey:@"credentials"];
    [super sendImage:anImage withCredentials:someCredentials];

    NSData * imageData = [self dataForImageUsingCompressionSettings:anImage];
    NSString * username = someCredentials.username;
    NSString * password = someCredentials.password;

    NSURL * url = [NSURL URLWithString:self.twitPicUrl];

    ASIFormDataRequest * req = [[ASIFormDataRequest alloc] initWithURL:url];

    [req setPostValue:[[self class] devKey] forKey:@"key"];
    [req setPostValue:username forKey:@"username"];
    [req setPostValue:password forKey:@"password"];
    [req setData:imageData forKey:@"media"];

    [req setDelegate:self];
    [req setDidFinishSelector:@selector(requestDidFinishLoading:)];
    [req setDidFailSelector:@selector(requestDidFail:)];

    [self.queue setUploadProgressDelegate:self];
    [self.queue setShowAccurateProgress:YES];
    [self.queue addOperation:req];

    [self.queue go];

    self.request = req;

    [req release];

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
    [self.queue cancelAllOperations];
}

#pragma mark ASIHTTPRequest delegate implementation

- (void)requestDidFinishLoading:(ASIHTTPRequest *)theRequest
{
    NSData * response = [theRequest responseData];
    NSLog(@"Received response from TwitPic: '%@'.",
        [[[NSString alloc]
        initWithData:response encoding:NSUTF8StringEncoding] autorelease]);

    [self.parser parse:response];

    if (self.parser.error) {
        NSError * error =
            [NSError errorWithLocalizedDescription:self.parser.error];
        [self.delegate service:self failedToPostImage:error];
    } else
        [self.delegate service:self didPostImageToUrl:self.parser.mediaUrl];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)requestDidFail:(ASIHTTPRequest *)failedRequest
{
    NSError * error = [failedRequest error];
    if (!([error.domain isEqualToString:NetworkRequestErrorDomain] &&
        error.code == ASIRequestCancelledErrorType)) {
        NSLog(@"Received error: %@", error);
        [self.delegate service:self failedToPostImage:error];
    }
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)setProgress:(float)newProgress
{
    [self.delegate service:self updateUploadProgress:newProgress];
}

#pragma mark Helpers for building the post body

- (void)uploadData:(NSData *)data toUrl:(NSURL *)url
{
    ASIHTTPRequest * theRequest = [[ASIHTTPRequest alloc] initWithURL:url];
    [theRequest setDelegate:self];
    [theRequest setDidFinishSelector:@selector(requestDidFinishLoading:)];
    [theRequest setDidFailSelector:@selector(requestDidFail:)];
    [theRequest appendPostData:data];

    [self.queue addOperation:theRequest];

    self.request = theRequest;
    [theRequest release];
}

+ (NSString *)devKey
{
    return @"023AGLTUc7533b166461ddb3bc523c54ab082240";
}

@end
