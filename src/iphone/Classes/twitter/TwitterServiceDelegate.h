//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "Tweet.h"

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
                  page:(NSNumber *)page;
- (void)failedToFetchDirectMessagesSinceUpdateId:(NSNumber *)updateId
                                            page:(NSNumber *)page
                                           error:(NSError *)error;

#pragma mark User info

@optional

- (void)userInfo:(User *) fetchedForUsername:(NSString *)username;
- (void)failedToFetchUserInfoForUsername:(NSString *)username
                                   error:(NSError *)error;

@end
