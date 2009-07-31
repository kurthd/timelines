//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PersonalFeedSelectionMgr.h"

@implementation PersonalFeedSelectionMgr

@synthesize allTimelineTweets, mentionsTimelineTweets;

- (void)dealloc
{
    [timelineDisplayMgr release];
    [allTimelineDataSource release];
    [mentionsTimelineDataSource release];

    [allTimelineTweets release];
    [mentionsTimelineTweets release];

    [super dealloc];
}

- (id)initWithTimelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
    allService:(TwitterService *)allService
    mentionsService:(TwitterService *)mentionsService
{
    if (self = [super init]) {
        timelineDisplayMgr = [aTimelineDisplayMgr retain];

        allTimelineDataSource =
            [[AllTimelineDataSource alloc] initWithTwitterService:allService];
        allService.delegate = allTimelineDataSource;
        mentionsTimelineDataSource =
            [[MentionsTimelineDataSource alloc]
            initWithTwitterService:mentionsService];
        mentionsService.delegate = mentionsTimelineDataSource;

        previousTab = -1;
        allTimelineRefresh = YES;
        mentionsTimelineRefresh = YES;

        allTimelinePagesShown = 1;
        mentionsTimelinePagesShown = 1;
    }

    return self;
}

- (void)tabSelected:(id)sender
{
    UISegmentedControl * control = (UISegmentedControl *)sender;
    [self tabSelectedWithIndex:control.selectedSegmentIndex];
}

- (void)tabSelectedWithIndex:(NSInteger)index
{
    NSLog(@"Tab selected");
    switch (previousTab) {
        case 0:
            self.allTimelineTweets = timelineDisplayMgr.timeline;
            allTimelinePagesShown = timelineDisplayMgr.pagesShown;
            allTimelineAllPagesLoaded = timelineDisplayMgr.allPagesLoaded;
            allTimelineRefresh = !timelineDisplayMgr.firstFetchReceived;
            break;
        case 1:
            self.mentionsTimelineTweets = timelineDisplayMgr.timeline;
            mentionsTimelinePagesShown = timelineDisplayMgr.pagesShown;
            mentionsTimelineAllPagesLoaded = timelineDisplayMgr.allPagesLoaded;
            mentionsTimelineRefresh = !timelineDisplayMgr.firstFetchReceived;
            break;
    }

    allTimelineDataSource.delegate = nil;
    mentionsTimelineDataSource.delegate = nil;

    switch (index) {
        case 0:
            NSLog(@"Selected all tweets tab; forcing refresh: %d",
                allTimelineRefresh);
            allTimelineDataSource.delegate = timelineDisplayMgr;
            timelineDisplayMgr.displayAsConversation = YES;
            [timelineDisplayMgr setService:allTimelineDataSource
                tweets:self.allTimelineTweets page:allTimelinePagesShown
                forceRefresh:allTimelineRefresh
                allPagesLoaded:allTimelineAllPagesLoaded];
            break;
        case 1:
            NSLog(@"Selected mentions tab");
            mentionsTimelineDataSource.delegate = timelineDisplayMgr;
            timelineDisplayMgr.displayAsConversation = NO;
            [timelineDisplayMgr setService:mentionsTimelineDataSource
                tweets:self.mentionsTimelineTweets
                page:mentionsTimelinePagesShown
                forceRefresh:mentionsTimelineRefresh
                allPagesLoaded:mentionsTimelineAllPagesLoaded];
            break;
    }

    previousTab = index;
}

- (void)refreshCurrentTabData
{
    NSInteger currentIndex = previousTab;
    previousTab = -1;
    [self tabSelectedWithIndex:currentIndex];
}

- (void)setCredentials:(TwitterCredentials *)credentials
{
    allTimelineRefresh = previousTab != 0 || allTimelineRefresh;
    mentionsTimelineRefresh = previousTab != 1 || mentionsTimelineRefresh;
}

@end
