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
+ (NSString *)composingTweetKey;
+ (NSString *)directMessageRecipientKey;
+ (NSString *)viewingUrlKey;
+ (NSString *)viewingHtmlKey;
+ (NSString *)currentlyViewedTweetIdKey;
+ (NSString *)currentlyViewedMentionIdKey;
+ (NSString *)currentlyViewedMessageIdKey;
+ (NSString *)timelineContentOffsetKey;

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
    BOOL composingTweet =
        [[dict objectForKey:[[self class] composingTweetKey]] boolValue];
    NSString * directMessageRecipient =
        [dict objectForKey:[[self class] directMessageRecipientKey]];
    NSString * viewingUrl = [dict objectForKey:[[self class] viewingUrlKey]];
    NSString * viewingHtml = [dict objectForKey:[[self class] viewingHtmlKey]];
    NSNumber * currentlyViewedTweetId =
        [dict objectForKey:[[self class] currentlyViewedTweetIdKey]];
    NSNumber * currentlyViewedMentionId =
        [dict objectForKey:[[self class] currentlyViewedMentionIdKey]];
    NSNumber * currentlyViewedMessageId =
        [dict objectForKey:[[self class] currentlyViewedMessageIdKey]];
    NSUInteger timelineContentOffset =
        [[dict objectForKey:[[self class] timelineContentOffsetKey]]
        unsignedIntValue];
    state.selectedTab = selectedTab;
    state.selectedTimelineFeed = selectedTimelineFeed;
    state.tabOrder = tabOrder;
    state.selectedSearchBookmarkIndex = selectedSearchBookmarkIndex;
    state.selectedPeopleBookmarkIndex = selectedPeopleBookmarkIndex;
    state.findPeopleText = findPeopleText;
    state.searchText = searchText;
    state.nearbySearch = nearbySearch;
    state.numNewMentions = numNewMentions;
    state.composingTweet = composingTweet;
    state.directMessageRecipient = directMessageRecipient;
    state.viewingUrl = viewingUrl;
    state.viewingHtml = viewingHtml;
    state.currentlyViewedTweetId = currentlyViewedTweetId;
    state.currentlyViewedMentionId = currentlyViewedMentionId;
    state.currentlyViewedMessageId = currentlyViewedMessageId;
    state.timelineContentOffset = timelineContentOffset;

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

    NSNumber * composingTweet = [NSNumber numberWithBool:state.composingTweet];
    [dict setObject:composingTweet forKey:[[self class] composingTweetKey]];

    if (state.directMessageRecipient)
        [dict setObject:state.directMessageRecipient
            forKey:[[self class] directMessageRecipientKey]];

    if (state.viewingUrl)
        [dict setObject:state.viewingUrl forKey:[[self class] viewingUrlKey]];

    if (state.viewingHtml)
        [dict setObject:state.viewingHtml forKey:[[self class] viewingHtmlKey]];

    if (state.currentlyViewedTweetId)
        [dict setObject:state.currentlyViewedTweetId
            forKey:[[self class] currentlyViewedTweetIdKey]];

    if (state.currentlyViewedMentionId)
        [dict setObject:state.currentlyViewedMentionId
            forKey:[[self class] currentlyViewedMentionIdKey]];

    if (state.currentlyViewedMessageId)
        [dict setObject:state.currentlyViewedMessageId
            forKey:[[self class] currentlyViewedMessageIdKey]];

    NSNumber * timelineContentOffset =
        [NSNumber numberWithUnsignedInt:state.timelineContentOffset];
    [dict setObject:timelineContentOffset
        forKey:[[self class] timelineContentOffsetKey]];

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

+ (NSString *)composingTweetKey
{
    return @"composingTweet";
}

+ (NSString *)directMessageRecipientKey
{
    return @"directMessageRecipient";
}

+ (NSString *)viewingUrlKey
{
    return @"viewingUrl";
}

+ (NSString *)viewingHtmlKey
{
    return @"viewingHtml";
}

+ (NSString *)currentlyViewedTweetIdKey
{
    return @"currentlyViewedTweetId";
}

+ (NSString *)currentlyViewedMentionIdKey
{
    return @"currentlyViewedMentionId";
}

+ (NSString *)currentlyViewedMessageIdKey
{
    return @"currentlyViewedMessageId";
}

+ (NSString *)timelineContentOffsetKey
{
    return @"timelineContentOffset";
}

@end
