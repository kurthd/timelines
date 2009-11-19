//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "User.h"
#import "Tweet.h"
#import "DirectMessage.h"

@protocol TwitterServiceDelegate <NSObject>

#pragma mark Account

@optional

- (void)credentialsValidated:(TwitterCredentials *)credentials;
- (void)failedToValidateCredentials:(TwitterCredentials *)credentials
                              error:(NSError *)error;

#pragma mark Sending tweets

@optional

- (void)tweetSentSuccessfully:(Tweet *)tweet;
- (void)failedToSendTweet:(NSString *)tweet error:(NSError *)error;

- (void)tweet:(Tweet *)tweet sentInReplyTo:(NSNumber *)tweetId;
- (void)failedToReplyToTweet:(NSNumber *)tweetId
                    withText:(NSString *)text
                       error:(NSError *)error;

#pragma mark Fetching individual tweets

- (void)fetchedTweet:(Tweet *)tweet withId:(NSNumber *)tweetId;
- (void)failedToFetchTweetWithId:(NSNumber *)tweetId error:(NSError *)error;

#pragma mark Deleting individual tweets

- (void)deletedTweetWithId:(NSNumber *)tweetId;
- (void)failedToDeleteTweetWithId:(NSNumber *)tweetId error:(NSError *)error;

#pragma mark Timelines

@optional

- (void)timeline:(NSArray *)timeline
    fetchedSinceUpdateId:(NSNumber *)updateId
                    page:(NSNumber *)page
                   count:(NSNumber *)count;
- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
                                      page:(NSNumber *)page
                                     count:(NSNumber *)count
                                     error:(NSError *)error;

- (void)timeline:(NSArray *)timeline
  fetchedForUser:(NSString *)user
   sinceUpdateId:(NSNumber *)updateId
            page:(NSNumber *)page
           count:(NSNumber *)count;
- (void)failedToFetchTimelineForUser:(NSString *)user
                       sinceUpdateId:(NSNumber *)updateId
                                page:(NSNumber *)page
                               count:(NSNumber *)count
                               error:(NSError *)error;

#pragma mark Mentions

- (void)mentions:(NSArray *)mentions
    fetchedSinceUpdateId:(NSNumber *)updateId
                    page:(NSNumber *)page
                   count:(NSNumber *)count;
- (void)failedToFetchMentionsSinceUpdateId:(NSNumber *)updateId
                                      page:(NSNumber *)page
                                     count:(NSNumber *)count
                                     error:(NSError *)error;

#pragma mark Direct messages

@optional

- (void)directMessages:(NSArray *)directMessages
  fetchedSinceUpdateId:(NSNumber *)updateId
                  page:(NSNumber *)page
                 count:(NSNumber *)count;
- (void)failedToFetchDirectMessagesSinceUpdateId:(NSNumber *)updateId
                                            page:(NSNumber *)page
                                           count:(NSNumber *)count
                                           error:(NSError *)error;

- (void)sentDirectMessages:(NSArray *)directMessages
      fetchedSinceUpdateId:(NSNumber *)updateId
                      page:(NSNumber *)page
                     count:(NSNumber *)count;
- (void)failedToFetchSentDirectMessagesSinceUpdateId:(NSNumber *)updateId
                                                page:(NSNumber *)page
                                               count:(NSNumber *)count
                                               error:(NSError *)error;

- (void)directMessage:(DirectMessage *)dm sentToUser:(NSString *)username;
- (void)failedToSendDirectMessage:(NSString *)text
                           toUser:(NSString *)username
                            error:(NSError *)error;

- (void)deletedDirectMessageWithId:(NSString *)directMessageId;
- (void)failedToDeleteDirectMessageWithId:(NSString *)directMessageId
                                    error:(NSError *)error;

#pragma mark Favorites

@optional

- (void)favorites:(NSArray *)favorites
   fetchedForUser:(NSString *)username
             page:(NSNumber *)page;
- (void)failedToFetchFavoritesForUser:(NSString *)user
                                 page:(NSNumber *)page
                                error:(NSError *)error;

- (void)tweet:(Tweet *)tweet markedAsFavorite:(BOOL)favorite;
- (void)failedToMarkTweet:(NSNumber *)tweetId
               asFavorite:(BOOL)favorite
                    error:(NSError *)error;

#pragma mark Lists

@optional

- (void)lists:(NSArray *)lists fetchedForUser:(NSString *)username
    fromCursor:(NSString *)cursor nextCursor:(NSString *)nextCursor;
- (void)failedToFetchListsForUser:(NSString *)username
                       fromCursor:(NSString *)cursor
                       error:(NSError *)error;

- (void)listSubscriptions:(NSArray *)listSubscriptions
           fetchedForUser:(NSString *)username
               fromCursor:(NSString *)cursor
               nextCursor:(NSString *)nextCursor;
- (void)failedToFetchListSubscriptionsForUser:(NSString *)username
                                   fromCursor:(NSString *)cursor
                                        error:(NSError *)error;

- (void)statuses:(NSArray *)statuses
fetchedForListId:(NSNumber *)listId
     ownedByUser:(NSString *)username
   sinceUpdateId:(NSNumber *)updateId
            page:(NSNumber *)page
           count:(NSNumber *)count;
- (void)failedToFetchStatusesForListId:(NSNumber *)listId
                           ownedByUser:(NSString *)username
                         sinceUpdateId:(NSNumber *)updateId
                                  page:(NSNumber *)page
                                 count:(NSNumber *)count
                                 error:(NSError *)error;


#pragma mark User info

@optional

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)username;
- (void)failedToFetchUserInfoForUsername:(NSString *)username
                                   error:(NSError *)error;

- (void)startedFollowingUsername:(NSString *)username;
- (void)failedToStartFollowingUsername:(NSString *)username
                                 error:(NSError *)error;

- (void)stoppedFollowingUsername:(NSString *)username;
- (void)failedToStopFollowingUsername:(NSString *)username
                                error:(NSError *)error;

#pragma mark Block/unblock users

- (void)blockedUser:(User *)user withUsername:(NSString *)username;
- (void)failedToBlockUserWithUsername:(NSString *)username
                                error:(NSError *)error;
- (void)unblockedUser:(User *)user
         withUsername:(NSString *)username;
- (void)failedToUnblockUserWithUsername:(NSString *)username
                                  error:(NSError *)error;

- (void)userIsBlocked:(NSString *)username;
- (void)userIsNotBlocked:(NSString *)username;
- (void)failedToCheckIfUserIsBlocked:(NSString *)username
                               error:(NSError *)error;

#pragma mark Social graph

@optional

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)username
         cursor:(NSString *)cursor nextCursor:(NSString *)nextCursor;
- (void)failedToFetchFriendsForUsername:(NSString *)username
                                 cursor:(NSString *)cursor
                                  error:(NSError *)error;

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)username
           cursor:(NSString *)cursor nextCursor:(NSString *)nextCursor;
- (void)failedToFetchFollowersForUsername:(NSString *)username
                                   cursor:(NSString *)cursor
                                    error:(NSError *)error;

- (void)user:(NSString *)username isFollowing:(NSString *)followee;
- (void)user:(NSString *)username isNotFollowing:(NSString *)followee;
- (void)failedToQueryIfUser:(NSString *)username
                isFollowing:(NSString *)followee
                      error:(NSError *)error;

#pragma mark Trends

- (void)fetchedCurrentTrends:(NSArray *)trends;
- (void)failedToFetchCurrentTrends:(NSError *)error;
- (void)fetchedDailyTrends:(NSArray *)trends;
- (void)failedToFetchDailyTrends:(NSError *)error;
- (void)fetchedWeeklyTrends:(NSArray *)trends;
- (void)failedToFetchWeeklyTrends:(NSError *)error;

#pragma mark Search results

- (void)searchResultsReceived:(NSArray *)newSearchResults
                     forQuery:(NSString *)query
                         page:(NSNumber *)page;
- (void)failedToFetchSearchResultsForQuery:(NSString *)query
                                      page:(NSNumber *)page
                                     error:(NSError *)error;

- (void)nearbySearchResultsReceived:(NSArray *)searchResults
                           forQuery:(NSString *)query
                               page:(NSNumber *)page
                           latitude:(NSNumber *)latitude
                          longitude:(NSNumber *)longitude
                             radius:(NSNumber *)radius
                    radiusIsInMiles:(BOOL)radiusIsInMiles;
- (void)failedToFetchNearbySearchResultsForQuery:(NSString *)searchResults
                                            page:(NSNumber *)page
                                        latitude:(NSNumber *)latitude
                                       longitude:(NSNumber *)longitude
                                          radius:(NSNumber *)radius
                                 radiusIsInMiles:(BOOL)radiusIsInMiles
                                           error:(NSError *)error;

@end
