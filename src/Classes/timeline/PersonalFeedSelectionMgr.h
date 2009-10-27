//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ToggleViewController.h"
#import "NetworkAwareViewController.h"

@interface PersonalFeedSelectionMgr : NSObject
{
    ToggleViewController * toggleController;
    NetworkAwareViewController * timelineController;
    NetworkAwareViewController * mentionsController;
}

- (id)initWithToggleController:(ToggleViewController *)tabController
    timelineController:(NetworkAwareViewController *)timelineController
    mentionsController:(NetworkAwareViewController *)mentionsController;

- (void)tabSelected:(id)sender;
- (void)tabSelectedWithIndex:(NSInteger)index;

@end
