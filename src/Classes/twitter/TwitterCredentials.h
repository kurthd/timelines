//
//  TwitterCredentials.h
//  twitch
//
//  Created by John A. Debay on 7/14/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ActiveTwitterCredentials;
@class DirectMessage;
@class DirectMessageDraft;
@class Mention;
@class TweetDraft;
@class TwitPicCredentials;
@class UserTweet;

@interface TwitterCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) TwitPicCredentials * twitPicCredentials;
@property (nonatomic, retain) ActiveTwitterCredentials * activeCredentials;
@property (nonatomic, retain) NSSet* userTimeline;
@property (nonatomic, retain) NSSet* directMessageDrafts;
@property (nonatomic, retain) TweetDraft * tweetDraft;
@property (nonatomic, retain) NSSet* mentions;
@property (nonatomic, retain) NSSet* directMessages;

@end


@interface TwitterCredentials (CoreDataGeneratedAccessors)
- (void)addUserTimelineObject:(UserTweet *)value;
- (void)removeUserTimelineObject:(UserTweet *)value;
- (void)addUserTimeline:(NSSet *)value;
- (void)removeUserTimeline:(NSSet *)value;

- (void)addDirectMessageDraftsObject:(DirectMessageDraft *)value;
- (void)removeDirectMessageDraftsObject:(DirectMessageDraft *)value;
- (void)addDirectMessageDrafts:(NSSet *)value;
- (void)removeDirectMessageDrafts:(NSSet *)value;

- (void)addMentionsObject:(Mention *)value;
- (void)removeMentionsObject:(Mention *)value;
- (void)addMentions:(NSSet *)value;
- (void)removeMentions:(NSSet *)value;

- (void)addDirectMessagesObject:(DirectMessage *)value;
- (void)removeDirectMessagesObject:(DirectMessage *)value;
- (void)addDirectMessages:(NSSet *)value;
- (void)removeDirectMessages:(NSSet *)value;

@end

