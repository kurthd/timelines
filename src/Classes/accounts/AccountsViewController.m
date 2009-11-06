//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsViewController.h"
#import "TwitterCredentials.h"
#import "UIColor+TwitchColors.h"
#import "SettingsReader.h"
#import "TimelineTableViewCellView.h"
#import "AccountTableViewCell.h"

NSInteger usernameSort(TwitterCredentials * user1,
                       TwitterCredentials * user2,
                       void * context)
{
    return [user1.username compare:user2.username];
}

@interface AccountsViewController ()

@property (nonatomic, copy) NSArray * accounts;

+ (void)configureSelectedAccountCell:(AccountTableViewCell *)cell;
+ (void)configureNormalAccountCell:(AccountTableViewCell *)cell;

@end

@implementation AccountsViewController

@synthesize delegate, selectedAccount, accounts, selectedAccountTarget,
    selectedAccountAction;

- (void)dealloc
{
    self.delegate = nil;
    self.accounts = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.tableView =
            [[[UITableView alloc]
            initWithFrame:self.tableView.frame style:UITableViewStyleGrouped]
            autorelease];
        self.tableView.allowsSelectionDuringEditing = NO;
        self.navigationItem.leftBarButtonItem = self.editButtonItem;

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            self.tableView.separatorColor = [UIColor twitchGrayColor];
            self.view.backgroundColor =
                [TimelineTableViewCellView defaultDarkThemeCellColor];
        }
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.accounts = [[self.delegate accounts]
        sortedArrayUsingFunction:usernameSort context:NULL];
    if (!self.selectedAccount)
        self.selectedAccount = [self.delegate currentActiveAccount];

    [self setEditing:NO animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
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
        AccountTableViewCell * cell =
            (AccountTableViewCell *)
            [self.tableView cellForRowAtIndexPath:indexPath];
        [[self class] configureSelectedAccountCell:cell];
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
    return self.accounts.count + 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    if (indexPath.row == self.accounts.count) {
        NSString * cellIdentifier = @"AddAccountTableViewCell";
        cell =
            [tv dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:cellIdentifier]
                autorelease];

        cell.textLabel.text = NSLocalizedString(@"account.addaccount", @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        NSString * cellIdentifier = @"AccountTableViewCell";
        AccountTableViewCell * accountCell =
            (AccountTableViewCell *)
            [tv dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!accountCell)
            accountCell =
                [[[AccountTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:cellIdentifier]
                autorelease];

        TwitterCredentials * account =
            [self.accounts objectAtIndex:indexPath.row];
        [accountCell setUsername:account.username];

        if ([account.username isEqualToString:self.selectedAccount.username])
            [[self class] configureSelectedAccountCell:accountCell];
        else
            [[self class] configureNormalAccountCell:accountCell];

        accountCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        accountCell.accessoryType =
            UITableViewCellAccessoryDetailDisclosureButton;
        accountCell.editingAccessoryType = UITableViewCellAccessoryNone;

        cell = accountCell;
    }

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(!self.tableView.editing, @"Should never be called while editing.");

    // toggle the active account
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (selectedAccountTarget)
        [selectedAccountTarget performSelector:selectedAccountAction
            withObject:nil];

    NSInteger accountIndex =
        [self.accounts indexOfObject:self.selectedAccount];
    if (accountIndex == indexPath.row)
        return;  // nothing changed

    NSIndexPath * oldIndexPath =
        [NSIndexPath indexPathForRow:accountIndex inSection:0];
 
    AccountTableViewCell * newCell =
        (AccountTableViewCell *)
        [self.tableView cellForRowAtIndexPath:indexPath];
    [[self class] configureSelectedAccountCell:newCell];
    self.selectedAccount = [self.accounts objectAtIndex:indexPath.row];

    AccountTableViewCell * oldCell =
        (AccountTableViewCell *)
        [self.tableView cellForRowAtIndexPath:oldIndexPath];
    [[self class] configureNormalAccountCell:oldCell];
}

- (void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    TwitterCredentials * c = [self.accounts objectAtIndex:indexPath.row];
    [self.delegate userWantsToEditAccount:c];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tv
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
        return;  // nothing to do

    TwitterCredentials * c = [self.accounts objectAtIndex:indexPath.row];
    if ([delegate userDeletedAccount:c]) {
        NSMutableArray * mc = [self.accounts mutableCopy];
        [mc removeObjectAtIndex:indexPath.row];
        self.accounts = mc;
        [mc release];

        // Delete the row from the data source
        [self.tableView
            deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                  withRowAnimation:YES];

        if (self.accounts.count == 0)
            self.selectedAccount = nil;
        else if (c == self.selectedAccount) {
            // deleted the active account; make the next one active
            NSInteger index = indexPath.row == 0 ? 0 : indexPath.row - 1;
            self.selectedAccount = [self.accounts objectAtIndex:index];

            NSIndexPath * newIndexPath =
                [NSIndexPath indexPathForRow:index inSection:0];
            AccountTableViewCell * cell =
                (AccountTableViewCell *)
                [self.tableView cellForRowAtIndexPath:newIndexPath];

            [[self class] configureSelectedAccountCell:cell];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"account.prompt", @"");
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(@"account.footer", @"");
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}

#pragma mark Private implementation

+ (void)configureSelectedAccountCell:(AccountTableViewCell *)cell
{
    [cell setSelectedAccount:YES];
    [cell setAvatarImage:[UIImage imageNamed:@"DefaultAvatar48x48.png"]];
    // cell.textLabel.textColor = [UIColor blackColor];
    // 
    // cell.imageView.image = [UIImage imageNamed:@"DefaultAvatar48x48.png"];

    // cell.imageView.image =
    //     [SettingsReader displayTheme] == kDisplayThemeDark ?
    //     [UIImage imageNamed:@"AccountSelectedCheckmarkDarkTheme.png"] :
    //     [UIImage imageNamed:@"AccountSelectedCheckmark.png"];
    // cell.imageView.highlightedImage =
    //     [UIImage imageNamed:@"AccountSelectedCheckmarkHighlighted.png"];
}

+ (void)configureNormalAccountCell:(AccountTableViewCell *)cell
{
    [cell setSelectedAccount:NO];
    [cell setAvatarImage:[UIImage imageNamed:@"DefaultAvatar48x48.png"]];
    // cell.textLabel.textColor =
    //     [SettingsReader displayTheme] == kDisplayThemeDark ?
    //     [UIColor whiteColor] : [UIColor lightGrayColor];

    // cell.imageView.image =
    //     [UIImage imageNamed:@"AccountNotSelectedFiller.png"];
    // cell.imageView.highlightedImage =
    //     [UIImage imageNamed:@"AccountNotSelectedFiller.png"];

    // cell.imageView.image = [UIImage imageNamed:@"DefaultAvatar48x48.png"];
    // cell.imageView.alpha = 0.4;
}

@end
