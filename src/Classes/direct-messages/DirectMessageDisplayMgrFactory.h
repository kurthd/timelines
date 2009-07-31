//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessagesDisplayMgr.h"
#import "NetworkAwareViewController.h"

#import "TimelineDisplayMgrFactory.h"
@interface DirectMessageDisplayMgrFactory : NSObject
{
    NSManagedObjectContext * context;
}

- (id)initWithContext:(NSManagedObjectContext *)context;

- (DirectMessagesDisplayMgr *)
    createDirectMessageDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineDisplayMgrFactory:
    (TimelineDisplayMgrFactory *)timelineDisplayMgrFactory;

@end
