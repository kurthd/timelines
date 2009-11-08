//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewDirectMessagesState : NSObject
{
    NSUInteger numNewMessages;
    NSMutableDictionary * newMessageCountByUser;
}

@property (nonatomic, assign) NSUInteger numNewMessages;

- (void)incrementCountBy:(NSInteger)count;

- (void)setCount:(NSUInteger)count forUserId:(NSNumber *)identifier;
- (NSUInteger)countForUserId:(NSNumber *)identifier;
- (NSDictionary *)allNewMessagesByUser;
- (void)clear;
- (void)incrementCountForUserId:(NSNumber *)identifier;

@end
