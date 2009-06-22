//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgrFactory.h"

@implementation TimelineDisplayMgrFactory

- (TimelineDisplayMgr *)
    createTimelineDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
{
    TimelineViewController * timelineController =
        [[[TimelineViewController alloc]
        initWithNibName:@"TimelineView" bundle:nil] autorelease];
    wrapperController.targetViewController = timelineController;

    TimelineDisplayMgr * timelineDisplayMgr =
        [[[TimelineDisplayMgr alloc] initWithWrapperController:wrapperController
        timelineController:timelineController] autorelease];

    return timelineDisplayMgr;
}
    
@end
