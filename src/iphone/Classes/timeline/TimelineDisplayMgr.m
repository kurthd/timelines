//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        timelineController = [aTimelineController retain];
    }

    return self;
}

@end
