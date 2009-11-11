//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGTwitterEngineDelegate.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@class YHOAuthTwitterEngine;

@interface TwitterService : NSObject <MGTwitterEngineDelegate>
{
    id<TwitterServiceDelegate> delegate;

    NSMutableDictionary * pendingRequests;

    TwitterCredentials * credentials;
    YHOAuthTwitterEngine * twitter;

    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;
@property (nonatomic, copy) TwitterCredentials * credentials;

#pragma mark Initialization

- (id)initWithTwitterCredentials:(TwitterCredentials *)someCredentials
                         context:(NSManagedObjectContext *)aContext;

- (id)clone;

#pragma mark Account

- (void)checkCredentials;

#pragma mark Sending tweets

// is 'tweet' a verb or a noun?
- (void)sendTweet:(NSString *)tweet;
- (void)sendTweet:(NSString *)tweet inReplyTo:(NSNumber *)referenceId;

#pragma mark Fetching individual tweets

- (void)fetchTweet:(NSNumber *)tweetId;

#pragma mark Deleting individual tweets

- (void)deleteTweet:(NSNumber *)tweetId;

#pragma mark Timeline

// for the user associated with 'credentials'
- (void)fetchTimelineSinceUpdateId:(NSNumber *)updateId
                              page:(NSNumber *)page
                             count:(NSNumber *)count;

// for an arbitrary user
- (void)fetchTimelineForUser:(NSString *)user
               sinceUpdateId:(NSNumber *)updateId
                        page:(NSNumber *)page
                       count:(NSNumber *)count;

#pragma mark Mentions

- (void)fetchMentionsSinceUpdateId:(NSNumber *)updateId
                              page:(NSNumber *)page
                             count:(NSNumber *)count;

#pragma mark Direct messages

- (void)fetchDirectMessagesSinceId:(NSNumber *)updateId
                              page:(NSNumber *)page
                             count:(NSNumber *)count;
- (void)fetchSentDirectMessagesSinceId:(NSNumber *)updateId
                                  page:(NSNumber *)page
                                 count:(NSNumber *)count;

- (void)sendDirectMessage:(NSString *)message to:(NSString *)username;

- (void)deleteDirectMessage:(NSString *)directMessageId;

#pragma mark Favorites

- (void)fetchFavoritesForUser:(NSString *)user page:(NSNumber *)page;
- (void)markTweet:(NSNumber *)tweetId asFavorite:(BOOL)favorite;

#pragma mark Lists

/**
 * Fetch lists owned by the logged-in user. The 'cursor' parameter allows
 * for paging through results, which will be returned 20 at a time and
 * cannot be customized. To begin paging, provide nil. When a page is
 * received, the cursor to retrieve the next page will be provided to the
 * delegate, or nil if no more pages are available.
 */
- (void)fetchListsFromCursor:(NSString *)cursor;

#pragma mark User info

- (void)fetchUserInfoForUsername:(NSString *)username;
- (void)followUser:(NSString *)username;
- (void)stopFollowingUser:(NSString *)username;

#pragma mark Blocking/unblocking users

- (void)blockUserWithUsername:(NSString *)username;
- (void)unblockUserWithUsername:(NSString *)username;
- (void)isUserBlocked:(NSString *)username;

#pragma mark Social graph

- (void)fetchFriendsForUser:(NSString *)user cursor:(NSString *)cursor;
- (void)fetchFollowersForUser:(NSString *)user cursor:(NSString *)cursor;
- (void)isUser:(NSString *)user following:(NSString *)followee;

#pragma mark Trends

- (void)fetchCurrentTrends;
- (void)fetchDailyTrends;
- (void)fetchWeeklyTrends;

#pragma mark Search

- (void)searchFor:(NSString *)queryString page:(NSNumber *)page;
- (void)searchFor:(NSString *)queryString
             page:(NSNumber *)page
         latitude:(NSNumber *)latitude
        longitude:(NSNumber *)longitude
           radius:(NSNumber *)radius
  radiusIsInMiles:(BOOL)radiusIsInMiles;

@end
