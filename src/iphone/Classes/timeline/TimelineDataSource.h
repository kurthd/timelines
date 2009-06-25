//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"

@protocol TimelineDataSource

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page;
- (TwitterCredentials *)credentials;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)fetchUserInfoForUsername:(NSString *)username;
- (void)fetchFriendsForUser:(NSString *)user page:(NSNumber *)page;
- (void)fetchFollowersForUser:(NSString *)user page:(NSNumber *)page;
- (void)isUser:(NSString *)user following:(NSString *)followee;
- (void)followUser:(NSString *)username;
- (void)stopFollowingUser:(NSString *)username;
- (void)markTweet:(NSString *)tweetId asFavorite:(BOOL)favorite;

@end
