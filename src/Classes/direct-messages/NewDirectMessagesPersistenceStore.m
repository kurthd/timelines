//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "NewDirectMessagesPersistenceStore.h"
#import "PListUtils.h"

@interface NewDirectMessagesPersistenceStore (Private)

+ (NSString *)plistName;
+ (NSString *)numNewMessagesKey;
+ (NSString *)newMessageCountByUserKey;
+ (NSString *)allAccountsPlistName;

@end

@implementation NewDirectMessagesPersistenceStore

- (NewDirectMessagesState *)load
{
    NewDirectMessagesState * state =
        [[[NewDirectMessagesState alloc] init] autorelease];

    NSDictionary * dict =
        [PlistUtils getDictionaryFromPlist:[[self class] plistName]];

    state.numNewMessages =
        [[dict objectForKey:[[self class] numNewMessagesKey]]
        unsignedIntValue];
    NSDictionary * newMessageCountByUser =
        [dict objectForKey:[[self class] newMessageCountByUserKey]];
    for (NSNumber * userId in newMessageCountByUser) {
        NSNumber * count = [newMessageCountByUser objectForKey:userId];
        [state setCount:[count intValue] forUserId:userId];
    }

    return state;
}

- (void)save:(NewDirectMessagesState *)state
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    NSNumber * numNewMessages =
        [NSNumber numberWithUnsignedInt:state.numNewMessages];
    [dict setObject:numNewMessages forKey:[[self class] numNewMessagesKey]];
    NSDictionary * allNewMessagesByUser = [state allNewMessagesByUser];
    [dict setObject:allNewMessagesByUser
        forKey:[[self class] newMessageCountByUserKey]];

    [PlistUtils saveDictionary:dict toPlist:[[self class] plistName]];
}

- (NSDictionary *)loadNewMessageCountsForAllAccounts
{
    return [PlistUtils getDictionaryFromPlist:
        [[self class] allAccountsPlistName]];
}

- (void)saveNewMessageCountsForAllAccounts:(NSDictionary *)state
{
    [PlistUtils saveDictionary:state
        toPlist:[[self class] allAccountsPlistName]];
}

+ (NSString *)plistName
{
    return @"NewDirectMessagesState";
}

+ (NSString *)numNewMessagesKey
{
    return @"numNewMessages";
}

+ (NSString *)newMessageCountByUserKey
{
    return @"newMessageCountByUser";
}

+ (NSString *)allAccountsPlistName
{
    return @"NewDirectMessagesByAccount";
}

@end
