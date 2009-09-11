//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService.h"
#import "SettingsReader.h"

@interface PhotoService ()

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSURL * videoUrl;
@property (nonatomic, retain) PhotoServiceCredentials * credentials;

@end

@implementation PhotoService

@synthesize delegate, image, videoUrl, credentials;

- (void)dealloc
{
    self.delegate = nil;
    self.image = nil;
    self.videoUrl = nil;
    self.credentials = nil;

    [super dealloc];
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = anImage;
    self.videoUrl = nil;
    self.credentials = someCredentials;
}

- (void)sendVideoAtUrl:(NSURL *)url
  withCredentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = nil;
    self.videoUrl = url;
    self.credentials = someCredentials;
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

    NSData * data = UIImageJPEGRepresentation(anImage, compression);
    NSLog(@"Image data: %d", data.length);

    return data;
}

@end
