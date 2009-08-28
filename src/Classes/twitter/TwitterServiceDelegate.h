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

- (void)tweet:(Tweet *)tweet sentInReplyTo:(NSString *)tweetId;
- (void)failedToReplyToTweet:(NSString *)tweetId
                    withText:(NSString *)text
                       error:(NSError *)error;

#pragma mark Fetching individual tweets

- (void)fetchedTweet:(Tweet *)tweet withId:(NSString *)tweetId;
- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error;

#pragma mark Deleting individual tweets

- (void)deletedTweetWithId:(NSString *)tweetId;
- (void)failedToDeleteTweetWithId:(NSString *)tweetId error:(NSError *)error;

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

#pragma mark Favorites

@optional

- (void)favorites:(NSArray *)favorites
   fetchedForUser:(NSString *)username
             page:(NSNumber *)page;
- (void)failedToFetchFavoritesForUser:(NSString *)user
                                 page:(NSNumber *)page
                                error:(NSError *)error;

- (void)tweet:(Tweet *)tweet markedAsFavorite:(BOOL)favorite;
- (void)failedToMarkTweet:(NSString *)tweetId
               asFavorite:(BOOL)favorite
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

#pragma mark Social graph

@optional

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)username
           page:(NSNumber *)page;
- (void)failedToFetchFriendsForUsername:(NSString *)username
                                   page:(NSNumber *)page
                                  error:(NSError *)error;

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)username
             page:(NSNumber *)page;
- (void)failedToFetchFollowersForUsername:(NSString *)username
                                     page:(NSNumber *)page
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

@end
