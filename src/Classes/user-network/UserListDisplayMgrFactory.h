//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SavedSearchMgr.h"
#import "UserListDisplayMgr.h"

@class UserListDisplayMgr;

@interface UserListDisplayMgrFactory : NSObject
{
    NSManagedObjectContext * context;
    SavedSearchMgr * findPeopleBookmarkMgr;
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr;

- (UserListDisplayMgr *)
    createUserListDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    showFollowing:(BOOL)showFollowing username:(NSString *)username;

@end
