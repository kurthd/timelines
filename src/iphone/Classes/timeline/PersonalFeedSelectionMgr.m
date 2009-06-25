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

        previousTab = -1;
        allTimelineRefresh = YES;
        mentionsTimelineRefresh = YES;
        messagesTimelineRefresh = YES;
    }

    return self;
}

- (void)tabSelected:(id)sender
{
    NSLog(@"Tab selected");
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
            timelineDisplayMgr.displayAsConversation = YES;
            [timelineDisplayMgr setShowInboxOutbox:NO];
            [timelineDisplayMgr setService:allTimelineDataSource
                tweets:self.allTimelineTweets page:allTimelinePagesShown
                forceRefresh:allTimelineRefresh];
            allTimelineRefresh = NO;
            break;
        case 1:
            NSLog(@"Selected mentions tab");
            service.delegate = mentionsTimelineDataSource;
            mentionsTimelineDataSource.delegate = timelineDisplayMgr;
            timelineDisplayMgr.displayAsConversation = NO;
            [timelineDisplayMgr setShowInboxOutbox:NO];
            [timelineDisplayMgr setService:mentionsTimelineDataSource
                tweets:self.mentionsTimelineTweets
                page:mentionsTimelinePagesShown
                forceRefresh:mentionsTimelineRefresh];
            mentionsTimelineRefresh = NO;
            break;
        case 2:
            NSLog(@"Selected direct messages tab");
            service.delegate = messagesTimelineDataSource;
            messagesTimelineDataSource.delegate = timelineDisplayMgr;
            timelineDisplayMgr.displayAsConversation = NO;
            [timelineDisplayMgr setShowInboxOutbox:YES];
            [timelineDisplayMgr setService:messagesTimelineDataSource
                tweets:self.messagesTimelineTweets
                page:messagesTimelinePagesShown
                forceRefresh:messagesTimelineRefresh];
            messagesTimelineRefresh = NO;
            break;
    }

    previousTab = segmentedControl.selectedSegmentIndex;
}

@end
