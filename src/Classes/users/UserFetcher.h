//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "TwitterService.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@protocol UserFetcherDelegate;

/*
 * The UserFetcher class is responsible for updating a User instance with
 * the most recent information from Twitter, including the user's avatar.
 */
@interface UserFetcher :
    NSObject <TwitterServiceDelegate, AsynchronousNetworkFetcherDelegate>
{
    id<UserFetcherDelegate> delegate;

    NSString * username;
    TwitterService * service;

    User * user;
}

@property (nonatomic, assign) id<UserFetcherDelegate> delegate;
@property (nonatomic, copy, readonly) NSString * username;
@property (nonatomic, retain) TwitterService * service;

- (id)initWithUsername:(NSString *)aUsername service:(TwitterService *)aService;

- (void)fetchUserInfo;

@end


@protocol UserFetcherDelegate <NSObject>

@optional

- (void)userUpdater:(UserFetcher *)updater fetchedUser:(User *)user;
- (void)userUpdater:(UserFetcher *)updater failedToFetchUser:(NSError *)error;

@end
