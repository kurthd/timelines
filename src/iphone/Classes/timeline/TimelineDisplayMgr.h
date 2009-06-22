//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TimelineViewController.h"
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"

@interface TimelineDisplayMgr : NSObject <TwitterServiceDelegate>
{
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;

    TwitterService * service;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(TwitterService *)service;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
