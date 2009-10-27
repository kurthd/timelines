//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDisplayMgr.h"
#import "ComposeTweetDisplayMgr.h"
#import "SavedSearchMgr.h"

@interface TimelineDisplayMgrFactory : NSObject
{
    NSManagedObjectContext * context;
    SavedSearchMgr * findPeopleBookmarkMgr;
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr;

- (TimelineDisplayMgr *)
    createTimelineDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
    title:(NSString *)title
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr;
    
@end
