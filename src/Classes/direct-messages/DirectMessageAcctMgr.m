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

    // fromUsername is nil when changing from a deleted account
    if (fromUsername) {
        NewDirectMessagesState * fromNewDirectMessagesState =
            displayMgr.newDirectMessagesState;
        [newMessageStates setObject:fromNewDirectMessagesState
                             forKey:fromUsername];
    }

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
    if ([[newMessageStates allKeys] count] == 0)
        [displayMgr.newDirectMessagesState clear];
    [displayMgr clearState];
}

- (NSDictionary *)directMessageCountsByAccount
{
    NSMutableDictionary * returnVal = [NSMutableDictionary dictionary];
    for (NSString * username in [newMessageStates allKeys]) {
        NewDirectMessagesState * dmState =
            [newMessageStates objectForKey:username];
        [returnVal setObject:dmState.allNewMessagesByUser forKey:username];
    }
    
    return returnVal;
}

- (void)setWithDirectMessageCountsByAccount:(NSDictionary *)dict
{
    for (NSString * acctUsername in [dict allKeys]) {
        NewDirectMessagesState * dmState =
            [[[NewDirectMessagesState alloc] init] autorelease];
        NSDictionary * newMessagesForAcct = [dict objectForKey:acctUsername];
        for (NSNumber * userId in [newMessagesForAcct allKeys]) {
            NSUInteger count =
                [[newMessagesForAcct objectForKey:userId] intValue];
            [dmState setCount:count forUserId:userId];
        }

        [newMessageStates setObject:dmState forKey:acctUsername];
    }
}

@end
