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

    state.selectedTab = selectedTab;
    state.selectedTimelineFeed = selectedTimelineFeed;
    state.viewedTweetId = viewedTweetId;

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
    [dict setObject:state.viewedTweetId forKey:[[self class] viewedTweetIdKey]];

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
    return @"viewedTweetIdKey";
}

@end
