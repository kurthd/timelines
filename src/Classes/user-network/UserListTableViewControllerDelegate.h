//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UserListTableViewControllerDelegate

- (void)showTweetsForUser:(NSString *)username;
- (void)loadMoreUsers;
- (void)userListViewWillAppear;

@end
