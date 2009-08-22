//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGTwitterEngine.h"

@class TwitterBasicAuthAuthenticator;

@protocol TwitterBasicAuthAuthenticatorDelegate

- (void)authenticator:(TwitterBasicAuthAuthenticator *)authenticator
    didAuthenticateUsername:(NSString *)username password:(NSString *)password;

- (void)authenticator:(TwitterBasicAuthAuthenticator *)authenticator
    didFailToAuthenticateUsername:(NSString *)username
                         password:(NSString *)password
                            error:(NSError *)error;

@end

@interface TwitterBasicAuthAuthenticator : NSObject <MGTwitterEngineDelegate>
{
    id<TwitterBasicAuthAuthenticatorDelegate> delegate;

    NSString * username;
    NSString * password;

    MGTwitterEngine * twitter;
}

@property (nonatomic, assign) id<TwitterBasicAuthAuthenticatorDelegate>
    delegate;

- (id)init;
- (id)initWithDelegate:(id<TwitterBasicAuthAuthenticatorDelegate>)aDelegate;

// only one authentication check is allowed at a time
- (void)authenticateUsername:(NSString *)username password:(NSString *)password;

@end
