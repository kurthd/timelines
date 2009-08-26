//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrPhotoService.h"
#import "FlickrCredentials.h"
#import "NSNumber+EncodingAdditions.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

@implementation FlickrPhotoService

- (void)dealloc
{
    [flickrContext release];

    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        NSString * key = [[self class] apiKey];
        NSString * secret = [[self class] sharedSecret];
        flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:key
                                                      sharedSecret:secret];
    }

    return self;
}

#pragma mark Public Implementation

- (void)sendImage:(UIImage *)anImage
  withCredentials:(FlickrCredentials *)ctls
{
    [super sendImage:anImage withCredentials:ctls];
    [flickrContext setAuthToken:ctls.token];

    OFFlickrAPIRequest * request =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:flickrContext];
    [request setDelegate:self];

    NSData * imageData = UIImagePNGRepresentation(image);
    NSInputStream * imageStream = [NSInputStream inputStreamWithData:imageData];
    [request uploadImageStream:imageStream
             suggestedFilename:@""
                      MIMEType:@"image/png"
                     arguments:nil];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)sendVideoAtUrl:(NSURL *)url
  withCredentials:(FlickrCredentials *)ctls
{
    [super sendVideoAtUrl:url withCredentials:ctls];
    [flickrContext setAuthToken:ctls.token];

    OFFlickrAPIRequest * request =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:flickrContext];
    [request setDelegate:self];

    NSData * videoData = [NSData dataWithContentsOfURL:url];
    NSInputStream * videoStream = [NSInputStream inputStreamWithData:videoData];
    [request uploadImageStream:videoStream
             suggestedFilename:@""
                      MIMEType:@"video/quicktime"
                     arguments:nil];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

+ (NSString *)apiKey
{
    return @"922ac08dae0049256158cf822f3760f9";
}

+ (NSString *)sharedSecret
{
    return @"c6252591e93c08e9";
}

#pragma mark OFFlickrAPIRequestDelegate implementation

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
    didCompleteWithResponse:(NSDictionary *)response
{
    NSString * photoIdString =
        [[response objectForKey:@"photoid"] objectForKey:@"_text"];
    NSNumber * photoId =
        [NSNumber numberWithLongLong:[photoIdString longLongValue]];
    NSString * shortPhotoId = [photoId base58EncodedString];

    NSString * shortUrl =
        [NSString stringWithFormat:@"http://flic.kr/p/%@", shortPhotoId];
    NSLog(@"short url: %@", shortUrl);

    if (self.image)
        [self.delegate service:self didPostImageToUrl:shortUrl];
    else if (self.videoUrl)
        [self.delegate service:self didPostVideoToUrl:shortUrl];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
        didFailWithError:(NSError *)error
{
    NSLog(@"Request failed: %@", error);

    if (self.image)
        [self.delegate service:self failedToPostImage:error];
    else if (self.videoUrl)
        [self.delegate service:self failedToPostVideo:error];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
    imageUploadSentBytes:(NSUInteger)inSentBytes
              totalBytes:(NSUInteger)inTotalBytes
{
    NSLog(@"Request uploaded %d of %d bytes", inSentBytes, inTotalBytes);
}

@end
