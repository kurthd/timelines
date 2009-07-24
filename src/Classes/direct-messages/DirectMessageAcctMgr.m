//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageAcctMgr.h"

@implementation DirectMessageAcctMgr

- (void)dealloc
{
    [displayMgr release];
    [newMessageStates release];
    [super dealloc];
}

- (id)initWithDirectMessagesDisplayMgr:(DirectMessagesDisplayMgr *)aDisplayMgr
{
    if (self = [super init]) {
        displayMgr = [aDisplayMgr retain];
        newMessageStates = [[NSMutableDictionary dictionary] retain];
    }

    return self;
}

- (void)processAccountChangeToUsername:(NSString *)toUsername
    fromUsername:(NSString *)fromUsername
{
    NSLog(@"Updating direct message display manager from '%@' to '%@'",
        fromUsername, toUsername);

    NewDirectMessagesState * fromNewDirectMessagesState =
        displayMgr.newDirectMessagesState;
    [newMessageStates setObject:fromNewDirectMessagesState forKey:fromUsername];

    [displayMgr clearState];

    NewDirectMessagesState * toNewDirectMessagesState =
        [newMessageStates objectForKey:toUsername];
    toNewDirectMessagesState =
        toNewDirectMessagesState ?
        toNewDirectMessagesState :
        [[[NewDirectMessagesState alloc] init] autorelease];
    displayMgr.newDirectMessagesState = toNewDirectMessagesState;
}

- (void)processAccountRemovedForUsername:(NSString *)username
{
    [newMessageStates removeObjectForKey:username];
}

@end
