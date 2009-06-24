//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsViewController.h"
#import "TwitterCredentials.h"

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

@synthesize delegate, accounts;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.accounts = [[self.delegate accounts]
        sortedArrayUsingFunction:usernameSort context:NULL];
}

#pragma mark Button actions

- (IBAction)userWantsToAddAccount:(id)sender
{
    if (self.tableView.editing)
        self.tableView.editing = NO;

    [self.delegate userWantsToAddAccount];
}

- (IBAction)editAccounts:(id)sender
{
}

#pragma mark Updating the table view data

- (void)accountAdded:(TwitterCredentials *)account
{
    if (self.tableView.editing)
        self.tableView.editing = NO;

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

    return cell;
}

- (void)          tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController =
    //     [[AnotherViewController alloc]
    //      initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)        tableView:(UITableView *)tv
    canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

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
        }
    }   
}

/*
// Override to support rearranging the table view.
- (void)     tableView:(UITableView *)tv
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)        tableView:(UITableView *)tv
    canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

@end
