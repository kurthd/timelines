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
    IBOutlet UIActivityIndicatorView * loadingMoreIndicator;
    IBOutlet UILabel * noMorePagesLabel;

    NSArray * users;
    NSMutableDictionary * alreadySent;
    
    NSArray * sortedUserCache;
}

@property (nonatomic, assign)
    NSObject<UserListTableViewControllerDelegate> * delegate;

@property (nonatomic, copy) NSArray * sortedUserCache;

- (void)setUsers:(NSArray *)users;
- (void)setAllPagesLoaded:(BOOL)allLoaded;

- (IBAction)loadMoreUsers:(id)sender;

@end
