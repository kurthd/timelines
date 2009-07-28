//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsViewController.h"
#import "AccountsTableViewCell.h"
#import "TwitterCredentials.h"
#import "UIColor+TwitchColors.h"

NSInteger usernameSort(TwitterCredentials * user1,
                       TwitterCredentials * user2,
                       void * context)
{
    return [user1.username compare:user2.username];
}

@interface AccountsViewController ()

@property (nonatomic, copy) NSArray * accounts;

@end

@implementation AccountsViewController

@synthesize delegate, selectedAccount, accounts;

- (void)dealloc
{
    self.delegate = nil;
    self.accounts = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationItem setLeftBarButtonItem:self.editButtonItem animated:NO];
    self.tableView.allowsSelectionDuringEditing = YES;

    remainInEditingMode = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.accounts = [[self.delegate accounts]
        sortedArrayUsingFunction:usernameSort context:NULL];
    self.selectedAccount = [self.delegate currentActiveAccount];

    remainInEditingMode = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (!remainInEditingMode)
        [self setEditing:NO animated:animated];
}

#pragma mark Button actions

- (IBAction)userWantsToAddAccount:(id)sender
{
    if (self.editing)
        [self setEditing:NO animated:YES];

    [self.delegate userWantsToAddAccount];
}

#pragma mark Updating the table view data

- (void)accountAdded:(TwitterCredentials *)account
{
    if (self.editing)
        self.editing = NO;

    NSArray * newAccounts = [[self.delegate accounts]
        sortedArrayUsingFunction:usernameSort context:NULL];

    NSInteger where = 0;
    for (NSInteger count = self.accounts.count; where < count; ++where) {
        TwitterCredentials * oldC = [self.accounts objectAtIndex:where];
        TwitterCredentials * newC = [newAccounts objectAtIndex:where];

        if (![oldC.username isEqualToString:newC.username])
            break;
    }

    self.accounts = newAccounts;

    NSIndexPath * indexPath =
        [NSIndexPath indexPathForRow:where inSection:0];

    [self.tableView
        insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
              withRowAnimation:UITableViewRowAnimationFade];

    if (self.accounts.count == 1) {
        UITableViewCell * cell =
            [self.tableView cellForRowAtIndexPath:indexPath];
        cell.textLabel.textColor = [UIColor twitchCheckedColor];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return self.accounts.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"AccountsTableViewCell";

    AccountsTableViewCell * cell = (AccountsTableViewCell *)
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell = [[[AccountsTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
          reuseIdentifier:CellIdentifier] autorelease];

    TwitterCredentials * account = [self.accounts objectAtIndex:indexPath.row];
    cell.textLabel.text = account.username;

    if ([account.username isEqualToString:self.selectedAccount.username]) {
        cell.textLabel.textColor = [UIColor twitchCheckedColor];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.accountSelected = YES;
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accountSelected = NO;
    }
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing) {
        TwitterCredentials * account =
            [self.accounts objectAtIndex:indexPath.row];
        [self.delegate userWantsToEditAccount:account];
        remainInEditingMode = YES;
    } else {
        // toggle the active account
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        NSInteger accountIndex =
            [self.accounts indexOfObject:self.selectedAccount];
        if (accountIndex == indexPath.row)
            return;  // nothing changed

        NSIndexPath * oldIndexPath =
            [NSIndexPath indexPathForRow:accountIndex inSection:0];
 
        AccountsTableViewCell * newCell = (AccountsTableViewCell *)
            [self.tableView cellForRowAtIndexPath:indexPath];
        if (newCell.accessoryType == UITableViewCellAccessoryNone) {
            newCell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.selectedAccount = [self.accounts objectAtIndex:indexPath.row];
            newCell.textLabel.textColor = [UIColor twitchCheckedColor];
            newCell.accountSelected = YES;
        }

        AccountsTableViewCell * oldCell = (AccountsTableViewCell *)
            [self.tableView cellForRowAtIndexPath:oldIndexPath];
        if (oldCell.accessoryType == UITableViewCellAccessoryCheckmark) {
            oldCell.accessoryType = UITableViewCellAccessoryNone;
            oldCell.textLabel.textColor = [UIColor blackColor];
            oldCell.accountSelected = NO;
        }
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tv
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TwitterCredentials * c = [self.accounts objectAtIndex:indexPath.row];
        if ([delegate userDeletedAccount:c]) {
            NSMutableArray * mc = [self.accounts mutableCopy];
            [mc removeObjectAtIndex:indexPath.row];
            self.accounts = mc;

            // Delete the row from the data source
            [self.tableView
             deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                   withRowAnimation:YES];

            if (self.accounts.count == 0)
                remainInEditingMode = NO;

            if (c == self.selectedAccount) {  // deleted the active account
                if (self.accounts.count == 0)
                    self.selectedAccount = nil;
                else {
                    NSInteger index =
                        indexPath.row == 0 ? 0 : indexPath.row - 1;
                    self.selectedAccount = [self.accounts objectAtIndex:index];

                    NSIndexPath * newIndexPath =
                        [NSIndexPath indexPathForRow:index inSection:0];
                    AccountsTableViewCell * cell = (AccountsTableViewCell *)
                        [self.tableView cellForRowAtIndexPath:newIndexPath];

                    cell.accountSelected = YES;
                }
            }
        }
    }   
}

@end
