//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UIStatePersistenceStore.h"
#import "PListUtils.h"

@interface UIStatePersistenceStore (Private)

+ (NSString *)plistName;
+ (NSString *)selectedTabKey;
+ (NSString *)selectedTimelineFeedKey;
+ (NSString *)viewedTweetIdKey;
+ (NSString *)tabOrderKey;
+ (NSString *)selectedPeopleBookmarkIndexKey;
+ (NSString *)selectedSearchBookmarkIndexKey;

@end

@implementation UIStatePersistenceStore

- (UIState *)load
{
    UIState * state = [[[UIState alloc] init] autorelease];

    NSDictionary * dict =
        [PlistUtils getDictionaryFromPlist:[[self class] plistName]];

    NSUInteger selectedTab =
        [[dict objectForKey:[[self class] selectedTabKey]] unsignedIntValue];
    NSUInteger selectedTimelineFeed =
        [[dict objectForKey:[[self class] selectedTimelineFeedKey]]
        unsignedIntValue];
    NSString * viewedTweetId =
        [dict objectForKey:[[self class] viewedTweetIdKey]];
    NSArray * tabOrder = [dict objectForKey:[[self class] tabOrderKey]];
    NSUInteger selectedSearchBookmarkIndex =
        [[dict objectForKey:[[self class] selectedSearchBookmarkIndexKey]]
        unsignedIntValue];
    NSUInteger selectedPeopleBookmarkIndex =
        [[dict objectForKey:[[self class] selectedPeopleBookmarkIndexKey]]
        unsignedIntValue];
    state.selectedTab = selectedTab;
    state.selectedTimelineFeed = selectedTimelineFeed;
    state.viewedTweetId = viewedTweetId;
    state.tabOrder = tabOrder;
    state.selectedSearchBookmarkIndex = selectedSearchBookmarkIndex;
    state.selectedPeopleBookmarkIndex = selectedPeopleBookmarkIndex;

    return state;
}

- (void)save:(UIState *)state
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    NSNumber * selectedTab = [NSNumber numberWithUnsignedInt:state.selectedTab];
    [dict setObject:selectedTab forKey:[[self class] selectedTabKey]];
    NSNumber * selectedTimelineFeed =
        [NSNumber numberWithInt:state.selectedTimelineFeed];
    [dict setObject:selectedTimelineFeed
        forKey:[[self class] selectedTimelineFeedKey]];

    if (state.viewedTweetId)
        [dict setObject:state.viewedTweetId
                 forKey:[[self class] viewedTweetIdKey]];

    [dict setObject:state.tabOrder forKey:[[self class] tabOrderKey]];

    NSNumber * selectedPeopleBookmarkIndex =
        [NSNumber numberWithUnsignedInt:state.selectedPeopleBookmarkIndex];
    [dict setObject:selectedPeopleBookmarkIndex
        forKey:[[self class] selectedPeopleBookmarkIndexKey]];
    NSNumber * selectedSearchBookmarkIndex =
        [NSNumber numberWithUnsignedInt:state.selectedSearchBookmarkIndex];
    [dict setObject:selectedSearchBookmarkIndex
        forKey:[[self class] selectedSearchBookmarkIndexKey]];

    [PlistUtils saveDictionary:dict toPlist:[[self class] plistName]];
}

+ (NSString *)plistName
{
    return @"UIState";
}

+ (NSString *)selectedTabKey
{
    return @"selectedTab";
}

+ (NSString *)selectedTimelineFeedKey
{
    return @"selectedTimelineFeedKey";
}

+ (NSString *)viewedTweetIdKey
{
    return @"viewedTweetId";
}

+ (NSString *)tabOrderKey
{
    return @"tabOrder";
}

+ (NSString *)selectedPeopleBookmarkIndexKey
{
    return @"selectedPeopleBookmarkIndex";
}

+ (NSString *)selectedSearchBookmarkIndexKey
{
    return @"selectedSearchBookmarkIndex";
}

@end
