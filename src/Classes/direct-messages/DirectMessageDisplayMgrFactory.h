//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessagesDisplayMgr.h"
#import "NetworkAwareViewController.h"
#import "TimelineDisplayMgrFactory.h"
#import "SavedSearchMgr.h"

@interface DirectMessageDisplayMgrFactory : NSObject
{
    NSManagedObjectContext * context;
    SavedSearchMgr * findPeopleBookmarkMgr;
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr;

- (DirectMessagesDisplayMgr *)
    createDirectMessageDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineDisplayMgrFactory:
    (TimelineDisplayMgrFactory *)timelineDisplayMgrFactory;

@end
