//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoServiceCredentials.h"

@class PhotoService;

@protocol PhotoServiceDelegate

- (void)service:(PhotoService *)service didPostImageToUrl:(NSString *)url;
- (void)service:(PhotoService *)service failedToPostImage:(NSError *)error;

- (void)service:(PhotoService *)service didPostVideoToUrl:(NSString *)url;
- (void)service:(PhotoService *)service failedToPostVideo:(NSError *)error;

- (void)service:(PhotoService *)service
    updateUploadProgress:(CGFloat)uploadProgress;

- (void)serviceDidUpdatePhotoTitle:(PhotoService *)service;
- (void)service:(PhotoService *)service
    failedToUpdatePhotoTitle:(NSError *)error;
- (void)serviceDidUpdateVideoTitle:(PhotoService *)service;
- (void)service:(PhotoService *)service
    failedToUpdateVideoTitle:(NSError *)error;

@end


@interface PhotoService : NSObject
{
    id<PhotoServiceDelegate> delegate;

    UIImage * image;
    NSURL * videoUrl;
    PhotoServiceCredentials * credentials;
}

@property (nonatomic, assign) id<PhotoServiceDelegate> delegate;
@property (nonatomic, retain, readonly) UIImage * image;
@property (nonatomic, retain, readonly) NSURL * videoUrl;
@property (nonatomic, retain, readonly) PhotoServiceCredentials * credentials;

- (void)sendImage:(UIImage *)image
  withCredentials:(PhotoServiceCredentials *)credentials;
- (void)sendVideoAtUrl:(NSURL *)url
  withCredentials:(PhotoServiceCredentials *)credentials;

- (void)cancelUpload;

- (void)setTitle:(NSString *)text forPhotoWithUrl:(NSString *)photoUrl
    credentials:(PhotoServiceCredentials *)credentials;
- (void)setTitle:(NSString *)text forVideoWithUrl:(NSString *)photoUrl
    credentials:(PhotoServiceCredentials *)credentials;

#pragma mark Protected methods to be used by subclasses

- (NSData *)dataForImageUsingCompressionSettings:(UIImage *)image;
- (NSString *)mimeTypeForImage:(UIImage *)image;

@end
