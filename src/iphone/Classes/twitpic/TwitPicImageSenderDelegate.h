//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TwitPicImageSender;

@protocol TwitPicImageSenderDelegate

- (void)sender:(TwitPicImageSender *)sender didPostImageToUrl:(NSString *)url;
- (void)sender:(TwitPicImageSender *)sender failedToPostImage:(NSError *)error;

@end
