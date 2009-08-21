//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoServiceCredentials.h"

@class PhotoService;

@protocol PhotoServiceDelegate

- (void)service:(PhotoService *)service didPostImageToUrl:(NSString *)url;
- (void)service:(PhotoService *)service failedToPostImage:(NSError *)error;

@end


@interface PhotoService : NSObject
{
    id<PhotoServiceDelegate> delegate;

    UIImage * image;
    PhotoServiceCredentials * credentials;
}

@property (nonatomic, assign) id<PhotoServiceDelegate> delegate;
@property (nonatomic, retain, readonly) UIImage * image;
@property (nonatomic, retain, readonly) PhotoServiceCredentials * credentials;

- (void)sendImage:(UIImage *)image
  withCredentials:(PhotoServiceCredentials *)credentials;

@end
