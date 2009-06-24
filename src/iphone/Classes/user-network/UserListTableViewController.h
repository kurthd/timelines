//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserListTableViewControllerDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@interface UserListTableViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    NSObject<UserListTableViewControllerDelegate> * delegate;

    IBOutlet UIView * footerView;
    IBOutlet UILabel * currentPagesLabel;
    IBOutlet UIButton * loadMoreButton;

    NSArray * users;
    NSMutableDictionary * avatarCache;
    NSMutableDictionary * alreadySent;
}

@property (nonatomic, assign)
    NSObject<UserListTableViewControllerDelegate> * delegate;

- (void)setUsers:(NSArray *)users;

- (IBAction)loadMoreUsers:(id)sender;

@end
