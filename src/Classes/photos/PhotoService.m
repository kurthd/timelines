//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService.h"

@interface PhotoService ()

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSData * video;
@property (nonatomic, retain) PhotoServiceCredentials * credentials;

@end

@implementation PhotoService

@synthesize delegate, image, video, credentials;

- (void)dealloc
{
    self.delegate = nil;
    self.image = nil;
    self.video = nil;
    self.credentials = nil;

    [super dealloc];
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = anImage;
    self.video = nil;
    self.credentials = someCredentials;
}

- (void)sendVideo:(NSData *)aVideo
  withCredentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = nil;
    self.video = aVideo;
    self.credentials = someCredentials;
}

@end
