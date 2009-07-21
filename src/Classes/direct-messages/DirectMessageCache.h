//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DirectMessageCache : NSObject
{
    NSMutableDictionary * receivedDirectMessages;
    NSMutableDictionary * sentDirectMessages;

    NSNumber * receivedUpdateId;
    NSNumber * sentUpdateId;
}

@property (nonatomic, copy) NSNumber * receivedUpdateId;
@property (nonatomic, copy) NSNumber * sentUpdateId;

- (void)addReceivedDirectMessages:(NSArray *)newDirectMessages;
- (NSDictionary *)receivedDirectMessages;

- (void)addSentDirectMessages:(NSArray *)newDirectMessages;
- (NSDictionary *)sentDirectMessages;

- (void)clear;

@end