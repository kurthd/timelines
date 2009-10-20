//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TwitterService.h"

@interface MentionTimelineDisplayMgr : NSObject 
{
    NetworkAwareViewController * wrapperController;
    TwitterService * service;
}

@end
