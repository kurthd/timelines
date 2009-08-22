//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitVidPhotoService.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "TwitVidCredentials.h"
#import "TwitVidCredentials+KeychainAdditions.h"

@interface TwitVidPhotoService ()

@property (nonatomic, retain) TwitVid * twitVid;

@end

@implementation TwitVidPhotoService

@synthesize twitVid;

- (void)dealloc
{
    self.twitVid = nil;
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
    [super sendVideoAtUrl:url withCredentials:ctls];

    self.twitVid = [TwitVid twitVidWithUsername:ctls.username
                                       password:ctls.password
                                       delegate:self];

    [self.twitVid uploadWithMediaFileAtURL:url
                                   message:nil
                                playlistId:nil
                         vidResponseParent:nil
                           youtubeUsername:nil
                           youtubePassword:nil
                                  userTags:nil
                               geoLatitude:nil
                              geoLongitude:nil
                               posterImage:nil
                                    source:@"Twitbit"
                                  realtime:NO];

    // HACK
    [[UIApplication sharedApplication] networkActivityDidFinish];
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

- (void)request:(TwitVidRequest*)request 
   didSendBytes:(uint64_t)bytesSent 
  totalExpected:(uint64_t)expectedBytes
{
    NSLog(@"Request: %@ did send bytes: %d, total expected: %d", request,
        bytesSent, expectedBytes);
}

@end
