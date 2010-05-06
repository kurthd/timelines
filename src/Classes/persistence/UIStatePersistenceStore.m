//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UIStatePersistenceStore.h"
#import "PListUtils.h"

@interface UIStatePersistenceStore (Private)

+ (NSString *)plistName;
+ (NSString *)composingTweetKey;
+ (NSString *)viewingUrlKey;
+ (NSString *)viewingHtmlKey;
+ (NSString *)currentlyViewedTweetIdKey;
+ (NSString *)currentlyViewedMentionIdKey;
+ (NSString *)timelineContentOffsetKey;
+ (NSString *)currentlyViewedTimelineKey;

@end

@implementation UIStatePersistenceStore

- (UIState *)load
{
    UIState * state = [[[UIState alloc] init] autorelease];

    NSDictionary * dict =
        [PlistUtils getDictionaryFromPlist:[[self class] plistName]];

    BOOL composingTweet =
        [[dict objectForKey:[[self class] composingTweetKey]] boolValue];
    NSString * viewingUrl = [dict objectForKey:[[self class] viewingUrlKey]];
    NSString * viewingHtml = [dict objectForKey:[[self class] viewingHtmlKey]];
    NSNumber * currentlyViewedTweetId =
        [dict objectForKey:[[self class] currentlyViewedTweetIdKey]];
    NSNumber * currentlyViewedMentionId =
        [dict objectForKey:[[self class] currentlyViewedMentionIdKey]];
    NSUInteger timelineContentOffset =
        [[dict objectForKey:[[self class] timelineContentOffsetKey]]
        unsignedIntValue];
    NSInteger currentlyViewedTimeline =
        [[dict objectForKey:[[self class] currentlyViewedTimelineKey]]
        unsignedIntValue];
    state.composingTweet = composingTweet;
    state.viewingUrl = viewingUrl;
    state.viewingHtml = viewingHtml;
    state.currentlyViewedTweetId = currentlyViewedTweetId;
    state.currentlyViewedMentionId = currentlyViewedMentionId;
    state.timelineContentOffset = timelineContentOffset;
    state.currentlyViewedTimeline = currentlyViewedTimeline;

    return state;
}

- (void)save:(UIState *)state
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    NSNumber * composingTweet = [NSNumber numberWithBool:state.composingTweet];
    [dict setObject:composingTweet forKey:[[self class] composingTweetKey]];

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

    NSNumber * timelineContentOffset =
        [NSNumber numberWithUnsignedInt:state.timelineContentOffset];
    [dict setObject:timelineContentOffset
        forKey:[[self class] timelineContentOffsetKey]];
    
    NSNumber * currentlyViewedTimeline =
        [NSNumber numberWithUnsignedInt:state.currentlyViewedTimeline];
    [dict setObject:currentlyViewedTimeline
        forKey:[[self class] currentlyViewedTimelineKey]];

    [PlistUtils saveDictionary:dict toPlist:[[self class] plistName]];
}

+ (NSString *)plistName
{
    return @"UIState";
}

+ (NSString *)composingTweetKey
{
    return @"composingTweet";
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

+ (NSString *)timelineContentOffsetKey
{
    return @"timelineContentOffset";
}

+ (NSString *)currentlyViewedTimelineKey
{
    return @"currentlyViewedTimeline";
}

@end
