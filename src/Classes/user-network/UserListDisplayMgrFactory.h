//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SavedSearchMgr.h"
#import "UserListDisplayMgr.h"
#import "ContactCache.h"
#import "ContactMgr.h"

@class UserListDisplayMgr;

@interface UserListDisplayMgrFactory : NSObject
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

- (UserListDisplayMgr *)
    createUserListDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    showFollowing:(BOOL)showFollowing username:(NSString *)username;

@end
