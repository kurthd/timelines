//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesViewController.h"

@interface PhotoServicesViewController ()

@property (nonatomic, copy) NSArray * services;

@end

@implementation PhotoServicesViewController

@synthesize delegate, credentials, services;

- (void)dealloc
{
    self.delegate = nil;

    self.credentials = nil;
    self.services = nil;

    [super dealloc];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"photoservices.view.title", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.services = [self.delegate servicesForAccount:self.credentials];
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return self.services.count + 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"PhotoServicesTableViewCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell =
            [[[UITableViewCell alloc]
              initWithFrame:CGRectZero reuseIdentifier:CellIdentifier]
             autorelease];
    }

    if (indexPath.row == self.services.count) {
        cell.textLabel.text =
            NSLocalizedString(@"photoservices.addaccount.label", @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.textLabel.text =
            [[self.services objectAtIndex:indexPath.row] description];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (BOOL)tableView:(UITableView *)tv
    shouldSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
