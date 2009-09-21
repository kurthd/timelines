//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitVidPhotoService.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "TwitVidCredentials.h"
#import "TwitVidCredentials+KeychainAdditions.h"

@interface TwitVidPhotoService ()

@property (nonatomic, retain) TwitVid * twitVid;
@property (nonatomic, retain) TwitVidRequest * request;

@end

@implementation TwitVidPhotoService

@synthesize twitVid, request;

- (void)dealloc
{
    self.twitVid = nil;
    self.request = nil;
    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

#pragma mark Public Implementation

- (void)sendImage:(UIImage *)anImage
  withCredentials:(TwitVidCredentials *)ctls
{
    NSAssert(NO, @"Photo uploading is not supported via TwitVid.");
}

- (void)sendVideoAtUrl:(NSURL *)url
  withCredentials:(TwitVidCredentials *)ctls
{
    self.image = nil;
    self.videoUrl = url;
    self.credentials = ctls;

    // exit from this function quickly so the app can continue functioning
    SEL selector = @selector(sendVideoOnTimer:);
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:self
                                   selector:selector
                                   userInfo:nil
                                    repeats:NO];
}

- (void)cancelUpload
{
    [self.request stop];
}

#pragma mark TwitVidDelegate implementation

- (void)request:(TwitVidRequest*)request 
    didFailWithError:(NSError *)error
{
    [self.delegate service:self failedToPostVideo:error];
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)request:(TwitVidRequest*)request 
    didReceiveResponse:(NSDictionary *)response
{
    NSLog(@"Received response from twitvid: %@", response);

    NSString * mediaUrl = [response objectForKey:@"media_url"];
    [self.delegate service:self didPostVideoToUrl:mediaUrl];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)request:(TwitVidRequest*)theRequest 
   didSendBytes:(uint64_t)bytesSent 
  totalExpected:(uint64_t)expectedBytes
{
    CGFloat progress = ((CGFloat) bytesSent) / ((CGFloat) expectedBytes);
    [self.delegate service:self updateUploadProgress:progress];
}

#pragma mark Private implementation

- (void)sendVideoOnTimer:(NSTimer *)timer
{
    TwitVidCredentials * ctls = (TwitVidCredentials *) self.credentials;

    self.twitVid = [TwitVid twitVidWithUsername:ctls.username
                                       password:ctls.password
                                       delegate:self];

    NSString * source =
        @"<a href=\"http://twitbitapp.com\">Twitbit for iPhone</a>";
    self.request = [self.twitVid uploadWithMediaFileAtURL:self.videoUrl
                                                  message:nil
                                               playlistId:nil
                                        vidResponseParent:nil
                                          youtubeUsername:nil
                                          youtubePassword:nil
                                                 userTags:nil
                                              geoLatitude:nil
                                             geoLongitude:nil
                                              posterImage:nil
                                                   source:source
                                                 realtime:NO];

    // HACK
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

@end
