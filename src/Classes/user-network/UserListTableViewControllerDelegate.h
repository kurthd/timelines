//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@protocol UserListTableViewControllerDelegate

- (void)showUserInfoForUser:(User *)aUser;
- (void)loadMoreUsers;
- (void)userListViewWillAppear;

@end
