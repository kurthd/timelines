//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XAuthTwitterEngine;
@protocol TwitterXauthenticatorDelegate;

@interface TwitterXauthenticator : NSObject
{
    id<TwitterXauthenticatorDelegate> delegate;

    NSString * consumerKey, * consumerSecret;
    NSString * username, * password;

    XAuthTwitterEngine * twitter;
}

@property (nonatomic, assign) id<TwitterXauthenticatorDelegate> delegate;

//
// Create a new instance with Twitbit for iPhone's oauth consumer key and secret
//
+ (id)twitbitForIphoneXauthenticator;

- (id)initWithConsumerKey:(NSString *)consumerKey
           consumerSecret:(NSString *)consumerSecret;

- (void)authWithUsername:(NSString *)username password:(NSString *)password;

@end

@protocol TwitterXauthenticatorDelegate

- (void)xauthenticator:(TwitterXauthenticator *)xauthenticator
       didReceiveToken:(NSString *)key
             andSecret:(NSString *)secret
           forUsername:(NSString *)username
           andPassword:(NSString *)password;

- (void)xauthenticator:(TwitterXauthenticator *)xauthenticator
  failedToAuthUsername:(NSString *)username
           andPassword:(NSString *)password
                 error:(NSError *)error;


@end

