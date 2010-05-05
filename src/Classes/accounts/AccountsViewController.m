//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsViewController.h"
#import "TwitterCredentials.h"
#import "UIColor+TwitchColors.h"
#import "SettingsReader.h"
#import "AccountTableViewCell.h"

NSInteger usernameSort(TwitterCredentials * user1,
                       TwitterCredentials * user2,
                       void * context)
{
    return [user1.username compare:user2.username];
}

@interface AccountsViewController ()

@property (nonatomic, copy) NSArray * accounts;
@property (nonatomic, retain) UIBarButtonItem * rightButton;

+ (void)configureNormalAccountCell:(AccountTableViewCell *)cell;

@end

@implementation AccountsViewController

@synthesize delegate, selectedAccount, accounts, selectedAccountTarget,
    selectedAccountAction, rightButton;

- (void)dealloc
{
    self.delegate = nil;
    self.accounts = nil;
    self.rightButton = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    self.tableView.separatorColor =
        [UIColor colorWithRed:.32 green:.32 blue:.32 alpha:1];
    self.tableView.backgroundColor = [UIColor defaultDarkThemeCellColor];
    self.tableView.allowsSelectionDuringEditing = NO;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.accounts = [[self.delegate accounts]
        sortedArrayUsingFunction:usernameSort context:NULL];
    if (!self.selectedAccount)
        self.selectedAccount = [self.delegate currentActiveAccount];

    [self.tableView reloadData];
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

    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:where inSection:0];

    [self.tableView
        insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
              withRowAnimation:UITableViewRowAnimationFade];
}

- (void)refreshAvatarImages
{
    for (UITableViewCell * cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[AccountTableViewCell class]]) {
            AccountTableViewCell * accountCell = (AccountTableViewCell *) cell;
            NSString * username = [accountCell username];
            UIImage * avatar = [delegate avatarImageForUsername:username];
            [accountCell setAvatarImage:avatar];
        }
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
    UITableViewCell * cell;
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

    UIImage * avatar = [delegate avatarImageForUsername:account.username];
    [accountCell setAvatarImage:avatar];
    
    [[self class] configureNormalAccountCell:accountCell];
    
    accountCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    accountCell.accessoryType =
        UITableViewCellAccessoryDisclosureIndicator;
    accountCell.editingAccessoryType = UITableViewCellAccessoryNone;

    cell = accountCell;

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(!self.tableView.editing, @"Should never be called while editing.");

    NSInteger accountIndex =
        [self.accounts indexOfObject:self.selectedAccount];
    if (accountIndex != indexPath.row) {
        NSIndexPath * oldIndexPath =
            [NSIndexPath indexPathForRow:accountIndex inSection:0];

        self.selectedAccount = [self.accounts objectAtIndex:indexPath.row];

        AccountTableViewCell * oldCell =
            (AccountTableViewCell *)
            [self.tableView cellForRowAtIndexPath:oldIndexPath];
        [[self class] configureNormalAccountCell:oldCell];
    }

    if (selectedAccountTarget)
        [selectedAccountTarget performSelector:selectedAccountAction
            withObject:nil];
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
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != [accounts count];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    if (editing) {
        self.rightButton = self.navigationItem.rightBarButtonItem;
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
    } else {
        if (self.rightButton)
            [self.navigationItem setRightBarButtonItem:self.rightButton
                                              animated:animated];
    }
}

#pragma mark Private implementation

+ (void)configureNormalAccountCell:(AccountTableViewCell *)cell
{
    [cell setSelectedAccount:NO];
}

@end
