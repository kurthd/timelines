//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConversationPreview : NSObject
{
    id otherUserId;
    NSString * otherUserName;
    NSString * mostRecentMessage;
    NSDate * mostRecentMessageDate;
    NSUInteger numNewMessages;
}

@property (nonatomic, readonly) id otherUserId;
@property (nonatomic, readonly) NSString * otherUserName;
@property (nonatomic, readonly) NSString * mostRecentMessage;
@property (nonatomic, readonly) NSDate * mostRecentMessageDate;
@property (nonatomic, assign) NSUInteger numNewMessages;

- (id)initWithOtherUserId:(id)otherUserId
    otherUserName:(NSString *)otherUserName
    mostRecentMessage:(NSString *)mostRecentMessage
    mostRecentMessageDate:(NSDate *)mostRecentMessageDate
    numNewMessages:(NSUInteger)numNewMessages;

@end
