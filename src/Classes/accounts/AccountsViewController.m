//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsViewController.h"
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

+ (void)configureSelectedAccountCell:(UITableViewCell *)cell;
+ (void)configureNormalAccountCell:(UITableViewCell *)cell;

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
    self.tableView.allowsSelectionDuringEditing = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.accounts = [[self.delegate accounts]
        sortedArrayUsingFunction:usernameSort context:NULL];
    self.selectedAccount = [self.delegate currentActiveAccount];

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
    return self.accounts.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"AccountsTableViewCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell = [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
          reuseIdentifier:CellIdentifier] autorelease];

    TwitterCredentials * account = [self.accounts objectAtIndex:indexPath.row];
    cell.textLabel.text = account.username;

    if ([account.username isEqualToString:self.selectedAccount.username])
        [[self class] configureSelectedAccountCell:cell];
    else
        [[self class] configureNormalAccountCell:cell];

    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.editingAccessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(!self.tableView.editing, @"Should never be called while editing.");

    // toggle the active account
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger accountIndex =
        [self.accounts indexOfObject:self.selectedAccount];
    if (accountIndex == indexPath.row)
        return;  // nothing changed

    NSIndexPath * oldIndexPath =
        [NSIndexPath indexPathForRow:accountIndex inSection:0];
 
    UITableViewCell * newCell =
        [self.tableView cellForRowAtIndexPath:indexPath];
    [[self class] configureSelectedAccountCell:newCell];
    self.selectedAccount = [self.accounts objectAtIndex:indexPath.row];

    UITableViewCell * oldCell =
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
            UITableViewCell * cell =
                [self.tableView cellForRowAtIndexPath:newIndexPath];

            [[self class] configureSelectedAccountCell:cell];
        }
    }
}

#pragma mark Private implementation

+ (void)configureSelectedAccountCell:(UITableViewCell *)cell
{
    cell.textLabel.textColor = [UIColor twitchCheckedColor];
    cell.imageView.image =
        [UIImage imageNamed:@"AccountSelectedCheckmark.png"];
    cell.imageView.highlightedImage =
        [UIImage imageNamed:@"AccountSelectedCheckmarkHighlighted.png"];
}

+ (void)configureNormalAccountCell:(UITableViewCell *)cell
{
    cell.textLabel.textColor = [UIColor blackColor];
    cell.imageView.image =
        [UIImage imageNamed:@"AccountNotSelectedFiller.png"];
    cell.imageView.highlightedImage =
        [UIImage imageNamed:@"AccountNotSelectedFiller.png"];
}

@end
