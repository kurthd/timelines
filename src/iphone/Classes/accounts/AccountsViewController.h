//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AccountsViewControllerDelegate

- (NSArray *)accounts;

@end

@interface AccountsViewController : UITableViewController
{
    id<AccountsViewControllerDelegate> delegate;

    NSArray * accounts;
}

@property (nonatomic, assign) id<AccountsViewControllerDelegate> delegate;

- (IBAction)addAccount:(id)sender;
- (IBAction)editAccounts:(id)sender;

@end
