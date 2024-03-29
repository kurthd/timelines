//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageCache.h"

@implementation DirectMessageCache

@synthesize receivedUpdateId, sentUpdateId;

- (void)dealloc
{
    [receivedDirectMessages release];
    [sentDirectMessages release];
    [receivedUpdateId release];
    [sentUpdateId release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        receivedDirectMessages = [[NSMutableDictionary dictionary] retain];
        sentDirectMessages = [[NSMutableDictionary dictionary] retain];
    }

    return self;
}

- (void)addReceivedDirectMessage:(DirectMessage *)message
{
    [receivedDirectMessages setObject:message forKey:message.identifier];
}

- (void)addReceivedDirectMessages:(NSArray *)newDirectMessages
{
    for (DirectMessage * message in newDirectMessages)
        [receivedDirectMessages setObject:message forKey:message.identifier];
}

- (NSDictionary *)receivedDirectMessages
{
    return [[receivedDirectMessages copy] autorelease];
}

- (void)addSentDirectMessage:(DirectMessage *)message
{
    [sentDirectMessages setObject:message forKey:message.identifier];
}

- (void)addSentDirectMessages:(NSArray *)newDirectMessages
{
    for (DirectMessage * message in newDirectMessages)
        [sentDirectMessages setObject:message forKey:message.identifier];
}

- (void)removeDirectMessageWithId:(NSNumber *)identifier
{
    [sentDirectMessages removeObjectForKey:identifier];
    [receivedDirectMessages removeObjectForKey:identifier];
}

- (NSDictionary *)sentDirectMessages
{
    return [[sentDirectMessages copy] autorelease];
}

- (void)clear
{
    [receivedDirectMessages removeAllObjects];
    [sentDirectMessages removeAllObjects];
    receivedUpdateId = nil;
    sentUpdateId = nil;
}

@end
