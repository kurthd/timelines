//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessagesDisplayMgr.h"
#import "NetworkAwareViewController.h"
#import "TimelineDisplayMgrFactory.h"
#import "SavedSearchMgr.h"
#import "ContactCache.h"
#import "ContactMgr.h"

@interface DirectMessageDisplayMgrFactory : NSObject
{
    NSManagedObjectContext * context;
    SavedSearchMgr * findPeopleBookmarkMgr;
    ContactCache * contactCache;
    ContactMgr * contactMgr;
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr;

- (DirectMessagesDisplayMgr *)
    createDirectMessageDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineDisplayMgrFactory:
    (TimelineDisplayMgrFactory *)timelineDisplayMgrFactory;

@end
