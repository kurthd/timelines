//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDisplayMgr.h"
#import "ComposeTweetDisplayMgr.h"
#import "SavedSearchMgr.h"
#import "ContactCache.h"
#import "ContactMgr.h"

@interface TimelineDisplayMgrFactory : NSObject
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

- (TimelineDisplayMgr *)
    createTimelineDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
    title:(NSString *)title
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr;
    
@end
