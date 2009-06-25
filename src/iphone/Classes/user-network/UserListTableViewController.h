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
    
    NSArray * sortedUserCache;
}

@property (nonatomic, assign)
    NSObject<UserListTableViewControllerDelegate> * delegate;

@property (nonatomic, copy) NSArray * sortedUserCache;

- (void)setUsers:(NSArray *)users page:(NSUInteger)page;

- (IBAction)loadMoreUsers:(id)sender;

@end
