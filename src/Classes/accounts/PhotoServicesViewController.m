//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesViewController.h"
#import "PhotoServiceCredentials.h"

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

#pragma mark Public implementation

- (void)reloadDisplay
{
    self.services = [self.delegate servicesForAccount:self.credentials];
    [self.tableView reloadData];
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

    [self reloadDisplay];
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
            initWithStyle:UITableViewCellStyleValue1
            reuseIdentifier:CellIdentifier]
            autorelease];
    }

    if (indexPath.row == self.services.count) {
        cell.textLabel.text =
            NSLocalizedString(@"photoservices.addaccount.label", @"");
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    } else {
        PhotoServiceCredentials * psc =
            [self.services objectAtIndex:indexPath.row];
        cell.textLabel.text = [psc serviceName];
        cell.detailTextLabel.text = [psc accountDisplayName];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.services.count)  // adding a new account
        [self.delegate userWantsToAddNewPhotoService:self.credentials];
    else
        [self.delegate userWantsToEditAccountAtIndex:indexPath.row
                                         credentials:self.credentials];
}

@end
