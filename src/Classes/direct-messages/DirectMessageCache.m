//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageCache.h"
#import "DirectMessage.h"

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

- (void)addReceivedDirectMessages:(NSArray *)newDirectMessages
{
    for (DirectMessage * message in newDirectMessages)
        [receivedDirectMessages setObject:message forKey:message.identifier];
}

- (NSDictionary *)receivedDirectMessages
{
    return [[receivedDirectMessages copy] autorelease];
}

- (void)addSentDirectMessages:(NSArray *)newDirectMessages
{
    for (DirectMessage * message in newDirectMessages)
        [sentDirectMessages setObject:message forKey:message.identifier];
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
