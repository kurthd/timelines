//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService.h"
#import "SettingsReader.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@interface PhotoService ()

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSURL * videoUrl;
@property (nonatomic, retain) PhotoServiceCredentials * credentials;

@property (nonatomic, retain) ASINetworkQueue * queue;

- (ASIHTTPRequest *)requestForUploadingImage:(UIImage *)anImage
                             withCredentials:(PhotoServiceCredentials *)ctls;
- (ASIHTTPRequest *)requestForUploadingVideo:(NSData *)aVideo
                             withCredentials:(PhotoServiceCredentials *)ctls;

- (void)processImageUploadResponse:(NSData *)response;
- (void)processVideoUploadResponse:(NSData *)response;
- (void)processImageUploadFailure:(NSError *)error;
- (void)processVideoUploadFailure:(NSError *)error;

@end

@implementation PhotoService

@synthesize delegate, image, videoUrl, credentials;
@synthesize queue;

- (void)dealloc
{
    self.delegate = nil;
    self.image = nil;
    self.videoUrl = nil;
    self.credentials = nil;

    self.queue = nil;

    [super dealloc];
}

- (id)init
{
    if (self = [super init])
        queue = [[ASINetworkQueue alloc] init];

    return self;
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = anImage;
    self.videoUrl = nil;
    self.credentials = someCredentials;

    // exit from this function quickly so the app can continue functioning
    SEL selector = @selector(sendImageOnTimer:);
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:self
                                   selector:selector
                                   userInfo:nil
                                    repeats:NO];
}

- (void)sendVideoAtUrl:(NSURL *)url
  withCredentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = nil;
    self.videoUrl = url;
    self.credentials = someCredentials;

    // exit from this function quickly so the app can continue functioning
    SEL selector = @selector(sendVideoOnTimer:);
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:self
                                   selector:selector
                                   userInfo:nil
                                    repeats:NO];
}

- (void)setTitle:(NSString *)text forPhotoWithUrl:(NSString *)photoUrl
    credentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = nil;
    self.videoUrl = nil;
    self.credentials = someCredentials;
}

- (void)setTitle:(NSString *)text forVideoWithUrl:(NSString *)photoUrl
    credentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = nil;
    self.videoUrl = nil;
    self.credentials = someCredentials;
}

- (void)cancelUpload
{
    [self.queue cancelAllOperations];
}

- (NSData *)dataForImageUsingCompressionSettings:(UIImage *)anImage
{
    ComposeTweetImageQuality quality = [SettingsReader imageQuality];

    CGFloat compression = 0.0;
    switch (quality) {
        case kComposeTweetImageQualityLow:
            compression = 0.25;
            break;
        case kComposeTweetImageQualityMedium:
            compression = 0.65;
            break;
        case kComposeTweetImageQualityHigh:
            compression = 1.0;
            break;
    }

    return UIImageJPEGRepresentation(anImage, compression);
}

- (NSString *)mimeTypeForImage:(UIImage *)anImage
{
    return @"image/jpeg";
}

#pragma mark Private implementation

- (void)sendImageOnTimer:(NSTimer *)timer
{
    ASIHTTPRequest * req = [self requestForUploadingImage:self.image
                                          withCredentials:self.credentials];

    [req setDelegate:self];
    [req setDidFinishSelector:@selector(requestDidFinishLoading:)];
    [req setDidFailSelector:@selector(requestDidFail:)];

    [self.queue setUploadProgressDelegate:self];
    [self.queue setShowAccurateProgress:YES];
    [self.queue addOperation:req];

    [self.queue go];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)sendVideoOnTimer:(NSTimer *)timer
{
    NSData * videoData = [NSData dataWithContentsOfURL:self.videoUrl];
    ASIHTTPRequest * req = [self requestForUploadingVideo:videoData
                                          withCredentials:self.credentials];

    [req setDelegate:self];
    [req setDidFinishSelector:@selector(requestDidFinishLoading:)];
    [req setDidFailSelector:@selector(requestDidFail:)];

    [self.queue setUploadProgressDelegate:self];
    [self.queue setShowAccurateProgress:YES];
    [self.queue addOperation:req];

    [self.queue go];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

#pragma mark ASIHTTPRequest delegate implementation

- (void)requestDidFinishLoading:(ASIHTTPRequest *)request
{
    NSData * response = [request responseData];
    if (self.image)
        [self processImageUploadResponse:response];
    else if (self.videoUrl)
        [self processVideoUploadResponse:response];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)requestDidFail:(ASIHTTPRequest *)request
{
    NSError * error = [request error];

    // if the user cancels the upload, it shows up as an error, which we
    // want to suppress
    BOOL requestWasCancelled =
        ([error.domain isEqualToString:NetworkRequestErrorDomain] &&
        error.code == ASIRequestCancelledErrorType);

    if (!requestWasCancelled) {
        if (self.image)
            [self processImageUploadFailure:error];
        else if (self.videoUrl)
            [self processVideoUploadFailure:error];
    }

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)setProgress:(float)newProgress
{
    [self.delegate service:self updateUploadProgress:newProgress];
}

#pragma mark Private interface to be implemented by subclasses

- (ASIHTTPRequest *)requestForUploadingImage:(UIImage *)anImage
                             withCredentials:(PhotoServiceCredentials *)ctls
{
    NSAssert(NO, @"Must be implemented by subclasses.");
    return nil;
}

- (ASIHTTPRequest *)requestForUploadingVideo:(NSData *)aVideo
                             withCredentials:(PhotoServiceCredentials *)ctls
{
    NSAssert(NO, @"Must be implemented by subclasses.");
    return nil;
}

- (void)processImageUploadResponse:(NSData *)response
{
    NSAssert(NO, @"Must be implemented by subclasses.");
}

- (void)processVideoUploadResponse:(NSData *)response
{
    NSAssert(NO, @"Must be implemented by subclasses.");
}

- (void)processImageUploadFailure:(NSError *)error
{
    NSAssert(NO, @"Must be implemented by subclasses.");
}

- (void)processVideoUploadFailure:(NSError *)error
{
    NSAssert(NO, @"Must be implemented by subclasses.");
}

@end
