//
//  TwitterCredentials.h
//  twitch
//
//  Created by John A. Debay on 3/18/10.
//  Copyright 2010 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ActiveTwitterCredentials;
@class BitlyCredentials;
@class DirectMessage;
@class DirectMessageDraft;
@class InstapaperCredentials;
@class Mention;
@class PhotoServiceCredentials;
@class TweetDraft;
@class User;
@class UserTweet;
@class UserTwitterList;

@interface TwitterCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet* lists;
@property (nonatomic, retain) InstapaperCredentials * instapaperCredentials;
@property (nonatomic, retain) NSSet* userTimeline;
@property (nonatomic, retain) NSSet* directMessageDrafts;
@property (nonatomic, retain) BitlyCredentials * bitlyCredentials;
@property (nonatomic, retain) NSSet* directMessages;
@property (nonatomic, retain) NSSet* mentions;
@property (nonatomic, retain) ActiveTwitterCredentials * activeCredentials;
@property (nonatomic, retain) TweetDraft * tweetDraft;
@property (nonatomic, retain) User * user;
@property (nonatomic, retain) NSSet* photoServiceCredentials;

@end


@interface TwitterCredentials (CoreDataGeneratedAccessors)
- (void)addListsObject:(UserTwitterList *)value;
- (void)removeListsObject:(UserTwitterList *)value;
- (void)addLists:(NSSet *)value;
- (void)removeLists:(NSSet *)value;

- (void)addUserTimelineObject:(UserTweet *)value;
- (void)removeUserTimelineObject:(UserTweet *)value;
- (void)addUserTimeline:(NSSet *)value;
- (void)removeUserTimeline:(NSSet *)value;

- (void)addDirectMessageDraftsObject:(DirectMessageDraft *)value;
- (void)removeDirectMessageDraftsObject:(DirectMessageDraft *)value;
- (void)addDirectMessageDrafts:(NSSet *)value;
- (void)removeDirectMessageDrafts:(NSSet *)value;

- (void)addDirectMessagesObject:(DirectMessage *)value;
- (void)removeDirectMessagesObject:(DirectMessage *)value;
- (void)addDirectMessages:(NSSet *)value;
- (void)removeDirectMessages:(NSSet *)value;

- (void)addMentionsObject:(Mention *)value;
- (void)removeMentionsObject:(Mention *)value;
- (void)addMentions:(NSSet *)value;
- (void)removeMentions:(NSSet *)value;

- (void)addPhotoServiceCredentialsObject:(PhotoServiceCredentials *)value;
- (void)removePhotoServiceCredentialsObject:(PhotoServiceCredentials *)value;
- (void)addPhotoServiceCredentials:(NSSet *)value;
- (void)removePhotoServiceCredentials:(NSSet *)value;

@end

