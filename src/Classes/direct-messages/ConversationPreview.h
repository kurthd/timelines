//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DateDescription.h"

@interface ConversationPreview : NSObject
{
    id otherUserId;
    NSString * otherUserName;
    NSString * mostRecentMessage;
    NSDate * mostRecentMessageDate;
    NSUInteger numNewMessages;
    
    NSString * dateDescription; // cache for fast display
    DateDescription * descriptionComponents;
}

@property (nonatomic, readonly) id otherUserId;
@property (nonatomic, readonly) NSString * otherUserName;
@property (nonatomic, readonly) NSString * mostRecentMessage;
@property (nonatomic, readonly) NSDate * mostRecentMessageDate;
@property (nonatomic, readonly) DateDescription * descriptionComponents;
@property (nonatomic, assign) NSUInteger numNewMessages;

- (id)initWithOtherUserId:(id)otherUserId
    otherUserName:(NSString *)otherUserName
    mostRecentMessage:(NSString *)mostRecentMessage
    mostRecentMessageDate:(NSDate *)mostRecentMessageDate
    numNewMessages:(NSUInteger)numNewMessages;
    
- (NSString *)dateDescription;

@end
