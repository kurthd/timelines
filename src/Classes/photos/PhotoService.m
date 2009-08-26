//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService.h"

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

@end
