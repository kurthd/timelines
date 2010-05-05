//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterCredentials.h"

@protocol AccountsViewControllerDelegate

- (NSArray *)accounts;

- (void)userWantsToAddAccount;
- (BOOL)userDeletedAccount:(TwitterCredentials *)credentials;
- (void)userWantsToEditAccount:(TwitterCredentials *)credentials;

- (TwitterCredentials *)currentActiveAccount;

- (UIImage *)avatarImageForUsername:(NSString *)username;

@end

@interface AccountsViewController : UITableViewController
{
    id<AccountsViewControllerDelegate> delegate;

    id selectedAccountTarget;
    SEL selectedAccountAction;

    NSArray * accounts;
    TwitterCredentials * selectedAccount;

    UIBarButtonItem * rightButton;
}

@property (nonatomic, assign) id<AccountsViewControllerDelegate> delegate;

@property (nonatomic, assign) id selectedAccountTarget;
@property (nonatomic, assign) SEL selectedAccountAction;

@property (nonatomic, retain) TwitterCredentials * selectedAccount;

- (IBAction)userWantsToAddAccount:(id)sender;

- (void)accountAdded:(TwitterCredentials *)credentials;
- (void)refreshAvatarImages;

@end
