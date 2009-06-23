//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PersonalFeedSelectionMgr.h"

@implementation PersonalFeedSelectionMgr

- (void)dealloc
{
    [timelineDisplayMgr release];
    [allTimelineDataSource release];
    [messagesTimelineDataSource release];
    [mentionsTimelineDataSource release];
    [service release];
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
    }

    return self;
}

- (void)tabSelected:(id)sender
{
    UISegmentedControl * segmentedControl = (UISegmentedControl *)sender;
    allTimelineDataSource.delegate = nil;
    messagesTimelineDataSource.delegate = nil;

    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"Selected all tweets tab");
            service.delegate = allTimelineDataSource;
            allTimelineDataSource.delegate = timelineDisplayMgr;
            [timelineDisplayMgr setService:allTimelineDataSource
                tweets:nil page:1];
            break;
        case 1:
            NSLog(@"Selected mentions tab");
            service.delegate = mentionsTimelineDataSource;
            mentionsTimelineDataSource.delegate = timelineDisplayMgr;
            [timelineDisplayMgr setService:mentionsTimelineDataSource
                tweets:nil page:1];
            break;
        case 2:
            NSLog(@"Selected direct messages tab");
            service.delegate = messagesTimelineDataSource;
            messagesTimelineDataSource.delegate = timelineDisplayMgr;
            [timelineDisplayMgr setService:messagesTimelineDataSource
                tweets:nil page:1];
            break;
    }
}

@end
