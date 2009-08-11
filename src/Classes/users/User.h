//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <CoreData/CoreData.h>

@class DirectMessage;
@class Tweet;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * followersCount;
@property (nonatomic, retain) NSString * profileImageUrl;
@property (nonatomic, retain) NSString * webpage;
@property (nonatomic, retain) NSNumber * friendsCount;
@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * statusesCount;
@property (nonatomic, retain) NSSet* tweets;
@property (nonatomic, retain) NSSet* receivedDirectMessages;
@property (nonatomic, retain) NSSet* sentDirectMessages;

@end

@interface User (CoreDataGeneratedAccessors)
- (void)addTweetsObject:(Tweet *)value;
- (void)removeTweetsObject:(Tweet *)value;
- (void)addTweets:(NSSet *)value;
- (void)removeTweets:(NSSet *)value;

- (void)addReceivedDirectMessagesObject:(DirectMessage *)value;
- (void)removeReceivedDirectMessagesObject:(DirectMessage *)value;
- (void)addReceivedDirectMessages:(NSSet *)value;
- (void)removeReceivedDirectMessages:(NSSet *)value;

- (void)addSentDirectMessagesObject:(DirectMessage *)value;
- (void)removeSentDirectMessagesObject:(DirectMessage *)value;
- (void)addSentDirectMessages:(NSSet *)value;
- (void)removeSentDirectMessages:(NSSet *)value;

@end