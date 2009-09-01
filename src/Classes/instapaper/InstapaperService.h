//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstapaperCredentials.h"

@protocol InstapaperServiceDelegate <NSObject>

#pragma mark Authentication

@optional

-(void)authenticatedUsername:(NSString *)username
                    password:(NSString *)password;
- (void)failedToAuthenticateUsername:(NSString *)username
                            password:(NSString *)password
                               error:(NSError *)error;

#pragma mark Posting URLs

@optional

- (void)postedUrl:(NSString *)url;
- (void)failedToPostUrl:(NSString *)url error:(NSError *)error;

@end

@interface InstapaperService : NSObject
{
    id<InstapaperServiceDelegate> delegate;
    InstapaperCredentials * credentials;

    NSString * authenticationUrl;
    NSString * postUrl;

    NSString * username;
    NSString * password;
    NSString * urlToAdd;

    NSURLConnection * authenticationConnection;
    NSURLConnection * postUrlConnection;
}

@property (nonatomic, assign) id<InstapaperServiceDelegate> delegate;
@property (nonatomic, retain) InstapaperCredentials * credentials;

@property (nonatomic, copy, readonly) NSString * postUrl;

#pragma mark Authenticating a user

- (void)authenticateUsername:(NSString *)username password:(NSString *)password;
- (void)cancelAuthentication;

#pragma mark Saving URLs

- (void)addUrl:(NSString *)url;

@end
