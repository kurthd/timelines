//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PersonalFeedSelectionMgr.h"

@implementation PersonalFeedSelectionMgr

@synthesize allTimelineTweets, mentionsTimelineTweets, messagesTimelineTweets;

- (void)dealloc
{
    [timelineDisplayMgr release];
    [allTimelineDataSource release];
    [messagesTimelineDataSource release];
    [mentionsTimelineDataSource release];
    [service release];

    [allTimelineTweets release];
    [mentionsTimelineTweets release];
    [messagesTimelineTweets release];

    [super dealloc];
}

- (id)initWithTimelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
    service:(TwitterService *)aService
{
    if (self = [super init]) {
        timelineDisplayMgr = [aTimelineDisplayMgr retain];
        service = [aService retain];

        allTimelineDataSource =
            [[AllTimelineDataSource alloc] initWithTwitterService:service];
        messagesTimelineDataSource =
            [[MessagesTimelineDataSource alloc] initWithTwitterService:service];
        mentionsTimelineDataSource =
            [[MentionsTimelineDataSource alloc] initWithTwitterService:service];

        previousTab = 0;
    }

    return self;
}

- (void)tabSelected:(id)sender
{
    switch (previousTab) {
        case 0:
            self.allTimelineTweets = timelineDisplayMgr.timeline;
            allTimelinePagesShown = timelineDisplayMgr.pagesShown;
            break;
        case 1:
            self.mentionsTimelineTweets = timelineDisplayMgr.timeline;
            mentionsTimelinePagesShown = timelineDisplayMgr.pagesShown;
            break;
        case 2:
            self.messagesTimelineTweets = timelineDisplayMgr.timeline;
            messagesTimelinePagesShown = timelineDisplayMgr.pagesShown;
            break;
    }

    UISegmentedControl * segmentedControl = (UISegmentedControl *)sender;
    allTimelineDataSource.delegate = nil;
    messagesTimelineDataSource.delegate = nil;

    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"Selected all tweets tab");
            service.delegate = allTimelineDataSource;
            allTimelineDataSource.delegate = timelineDisplayMgr;
            [timelineDisplayMgr setService:allTimelineDataSource
                tweets:self.allTimelineTweets page:allTimelinePagesShown];
            break;
        case 1:
            NSLog(@"Selected mentions tab");
            service.delegate = mentionsTimelineDataSource;
            mentionsTimelineDataSource.delegate = timelineDisplayMgr;
            [timelineDisplayMgr setService:mentionsTimelineDataSource
                tweets:self.mentionsTimelineTweets
                page:mentionsTimelinePagesShown];
            break;
        case 2:
            NSLog(@"Selected direct messages tab");
            service.delegate = messagesTimelineDataSource;
            messagesTimelineDataSource.delegate = timelineDisplayMgr;
            [timelineDisplayMgr setService:messagesTimelineDataSource
                tweets:self.messagesTimelineTweets
                page:messagesTimelinePagesShown];
            break;
    }

    previousTab = segmentedControl.selectedSegmentIndex;
}

@end
