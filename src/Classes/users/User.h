//
//  User.h
//  twitch
//
//  Created by John A. Debay on 11/15/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Avatar.h"

@class Avatar;
@class DirectMessage;
@class Tweet;
@class TwitterCredentials;
@class TwitterList;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * followersCount;
@property (nonatomic, retain) NSString * webpage;
@property (nonatomic, retain) NSNumber * friendsCount;
@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * geoEnabled;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * statusesCount;
@property (nonatomic, retain) NSSet* sentDirectMessages;
@property (nonatomic, retain) NSSet* lists;
@property (nonatomic, retain) NSSet* tweets;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSSet* receivedDirectMessages;
@property (nonatomic, retain) Avatar * avatar;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addSentDirectMessagesObject:(DirectMessage *)value;
- (void)removeSentDirectMessagesObject:(DirectMessage *)value;
- (void)addSentDirectMessages:(NSSet *)value;
- (void)removeSentDirectMessages:(NSSet *)value;

- (void)addListsObject:(TwitterList *)value;
- (void)removeListsObject:(TwitterList *)value;
- (void)addLists:(NSSet *)value;
- (void)removeLists:(NSSet *)value;

- (void)addTweetsObject:(Tweet *)value;
- (void)removeTweetsObject:(Tweet *)value;
- (void)addTweets:(NSSet *)value;
- (void)removeTweets:(NSSet *)value;

- (void)addReceivedDirectMessagesObject:(DirectMessage *)value;
- (void)removeReceivedDirectMessagesObject:(DirectMessage *)value;
- (void)addReceivedDirectMessages:(NSSet *)value;
- (void)removeReceivedDirectMessages:(NSSet *)value;

@end

