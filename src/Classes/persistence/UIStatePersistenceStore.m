//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UIStatePersistenceStore.h"
#import "PListUtils.h"

@interface UIStatePersistenceStore (Private)

+ (NSString *)plistName;
+ (NSString *)selectedTabKey;
+ (NSString *)selectedTimelineFeedKey;
+ (NSString *)tabOrderKey;
+ (NSString *)selectedPeopleBookmarkIndexKey;
+ (NSString *)selectedSearchBookmarkIndexKey;
+ (NSString *)findPeopleTextKey;
+ (NSString *)searchTextKey;
+ (NSString *)nearbySearchKey;
+ (NSString *)numNewMentionsKey;

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
    NSArray * tabOrder = [dict objectForKey:[[self class] tabOrderKey]];
    NSUInteger selectedSearchBookmarkIndex =
        [[dict objectForKey:[[self class] selectedSearchBookmarkIndexKey]]
        unsignedIntValue];
    NSUInteger selectedPeopleBookmarkIndex =
        [[dict objectForKey:[[self class] selectedPeopleBookmarkIndexKey]]
        unsignedIntValue];
    NSString * findPeopleText =
        [dict objectForKey:[[self class] findPeopleTextKey]];
    NSString * searchText =
        [dict objectForKey:[[self class] searchTextKey]];
    BOOL nearbySearch =
        [[dict objectForKey:[[self class] nearbySearchKey]] boolValue];
    NSUInteger numNewMentions =
        [[dict objectForKey:[[self class] numNewMentionsKey]] unsignedIntValue];
    state.selectedTab = selectedTab;
    state.selectedTimelineFeed = selectedTimelineFeed;
    state.tabOrder = tabOrder;
    state.selectedSearchBookmarkIndex = selectedSearchBookmarkIndex;
    state.selectedPeopleBookmarkIndex = selectedPeopleBookmarkIndex;
    state.findPeopleText = findPeopleText;
    state.searchText = searchText;
    state.nearbySearch = nearbySearch;
    state.numNewMentions = numNewMentions;

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

    [dict setObject:state.tabOrder forKey:[[self class] tabOrderKey]];

    NSNumber * selectedPeopleBookmarkIndex =
        [NSNumber numberWithUnsignedInt:state.selectedPeopleBookmarkIndex];
    [dict setObject:selectedPeopleBookmarkIndex
        forKey:[[self class] selectedPeopleBookmarkIndexKey]];
    NSNumber * selectedSearchBookmarkIndex =
        [NSNumber numberWithUnsignedInt:state.selectedSearchBookmarkIndex];
    [dict setObject:selectedSearchBookmarkIndex
        forKey:[[self class] selectedSearchBookmarkIndexKey]];

    if (state.findPeopleText)
        [dict setObject:state.findPeopleText
            forKey:[[self class] findPeopleTextKey]];
    if (state.searchText)
        [dict setObject:state.searchText
            forKey:[[self class] searchTextKey]];

    NSNumber * nearbySearch = [NSNumber numberWithBool:state.nearbySearch];
    [dict setObject:nearbySearch forKey:[[self class] nearbySearchKey]];
    
    NSNumber * numNewMentions =
        [NSNumber numberWithUnsignedInt:state.numNewMentions];
    [dict setObject:numNewMentions forKey:[[self class] numNewMentionsKey]];

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

+ (NSString *)findPeopleTextKey
{
    return @"findPeopleText";
}

+ (NSString *)searchTextKey
{
    return @"searchText";
}

+ (NSString *)nearbySearchKey
{
    return @"nearbySearch";
}

+ (NSString *)numNewMentionsKey
{
    return @"numNewMentions";
}

@end
