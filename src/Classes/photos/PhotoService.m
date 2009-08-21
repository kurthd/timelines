//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService.h"

@interface PhotoService ()

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) PhotoServiceCredentials * credentials;

@end

@implementation PhotoService

@synthesize delegate, image, credentials;

- (void)dealloc
{
    self.delegate = nil;
    self.image = nil;
    self.credentials = nil;

    [super dealloc];
}

- (void)sendImage:(UIImage *)anImage
  withCredentials:(PhotoServiceCredentials *)someCredentials
{
    self.image = anImage;
    self.credentials = someCredentials;
}

@end
