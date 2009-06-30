//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitPicCredentials.h"
#import "TwitPicImageSenderDelegate.h"

@class TwitPicResponseParser;

@interface TwitPicImageSender : NSObject
{
    id<TwitPicImageSenderDelegate> delegate;

    NSString * twitPicUrl;

    UIImage * image;

    NSMutableData * data;
    NSURLConnection * connection;

    TwitPicResponseParser * parser;
}

@property (nonatomic, assign) id<TwitPicImageSenderDelegate> delegate;
@property (nonatomic, retain, readonly) UIImage * image;

- (id)initWithUrl:(NSString *)aUrl;

- (void)sendImage:(UIImage *)image
  withCredentials:(TwitPicCredentials *)credentials;

@end
