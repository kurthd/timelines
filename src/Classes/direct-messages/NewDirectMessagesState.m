//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "NewDirectMessagesState.h"

@implementation NewDirectMessagesState

@synthesize numNewMessages;

- (void)dealloc
{
    [newMessageCountByUser release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
        newMessageCountByUser = [[NSMutableDictionary dictionary] retain];

    return self;
}

- (void)incrementCountBy:(NSInteger)count
{
    numNewMessages += count;
}

- (void)setCount:(NSUInteger)count forUserId:(NSNumber *)identifier
{
    NSNumber * countAsNum = [NSNumber numberWithInt:count];
    [newMessageCountByUser setObject:countAsNum forKey:identifier];
    
    // force badge to be consistent with unread messages at this point
    numNewMessages = 0;
    for (NSNumber * userCount in [newMessageCountByUser allValues])
        numNewMessages += [userCount intValue];
}

- (NSUInteger)countForUserId:(NSNumber *)identifier
{
    NSNumber * countAsNumber = [newMessageCountByUser objectForKey:identifier];
    
    return countAsNumber ? [countAsNumber intValue] : 0;
}

- (void)clear
{
    [newMessageCountByUser removeAllObjects];
    numNewMessages = 0;
}

- (NSDictionary *)allNewMessagesByUser
{
    return [[newMessageCountByUser copy] autorelease];
}

- (void)incrementCountForUserId:(NSNumber *)identifier
{
    NSNumber * numMessagesAsNumber =
        [newMessageCountByUser objectForKey:identifier];
    NSUInteger numMessagesForUser =
        numMessagesAsNumber ? [numMessagesAsNumber intValue] + 1 : 1;
    [newMessageCountByUser
        setObject:[NSNumber numberWithInt:numMessagesForUser]
        forKey:identifier];
}

@end
