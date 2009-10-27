//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PersonalFeedSelectionMgr.h"

@implementation PersonalFeedSelectionMgr

- (void)dealloc
{
    [toggleController release];
    [timelineController release];
    [mentionsController release];
    [super dealloc];
}

- (id)initWithToggleController:(ToggleViewController *)aToggleController
    timelineController:(NetworkAwareViewController *)aTimelineController
    mentionsController:(NetworkAwareViewController *)aMentionsController
{
    if (self = [super init]) {
        toggleController = [aToggleController retain];
        timelineController = [aTimelineController retain];
        mentionsController = [aMentionsController retain];
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
    NSLog(@"Timeline segmented control index selected: %d", index);

    NetworkAwareViewController * controller =
        index == 0 ? timelineController : mentionsController;
    [toggleController setChildController:controller];
}

@end
