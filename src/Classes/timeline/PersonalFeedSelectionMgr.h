//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDisplayMgr.h"
#import "AllTimelineDataSource.h"
#import "MentionsTimelineDataSource.h"
#import "TwitterService.h"

@interface PersonalFeedSelectionMgr : NSObject
{
    TimelineDisplayMgr * timelineDisplayMgr;
    AllTimelineDataSource * allTimelineDataSource;
    MentionsTimelineDataSource * mentionsTimelineDataSource;

    NSDictionary * allTimelineTweets;
    NSUInteger allTimelinePagesShown;
    BOOL allTimelineRefresh;
    BOOL allTimelineAllPagesLoaded;

    NSDictionary * mentionsTimelineTweets;
    NSUInteger mentionsTimelinePagesShown;
    BOOL mentionsTimelineRefresh;
    BOOL mentionsTimelineAllPagesLoaded;

    NSInteger previousTab;
}

@property (nonatomic, copy) NSDictionary * allTimelineTweets;
@property (nonatomic, copy) NSDictionary * mentionsTimelineTweets;

- (id)initWithTimelineDisplayMgr:(TimelineDisplayMgr *)timelineDisplayMgr
    allService:(TwitterService *)allService
    mentionsService:(TwitterService *)mentionsService;

- (void)tabSelected:(id)sender;
- (void)tabSelectedWithIndex:(NSInteger)index;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)refreshCurrentTabData;

@end
