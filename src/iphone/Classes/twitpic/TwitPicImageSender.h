//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "TwitPicImageSenderDelegate.h"

@class TwitPicResponseParser;

@interface TwitPicImageSender : NSObject
{
    id<TwitPicImageSenderDelegate> delegate;

    NSString * twitPicUrl;

    UIImage * image;
    TwitterCredentials * credentials;

    NSMutableData * data;
    NSURLConnection * connection;

    TwitPicResponseParser * parser;
}

@property (nonatomic, assign) id<TwitPicImageSenderDelegate> delegate;
@property (nonatomic, retain, readonly) UIImage * image;
@property (nonatomic, retain, readonly) TwitterCredentials * credentials;

- (id)initWithUrl:(NSString *)aUrl;

- (void)sendImage:(UIImage *)image
  withCredentials:(TwitterCredentials *)credentials;

@end
