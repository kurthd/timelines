//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesViewController.h"
#import "PhotoServiceCredentials.h"

static const NSInteger NUM_SECTIONS = 2;
enum {
    kDefaultsSection,
    kAccountsSection
};

static const NSInteger NUM_DEFAULTS_ROWS = 2;
enum {
    kPhotoDefaults,
    kVideoDefaults
};

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
    return NUM_SECTIONS;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger nrows = 0;

    if (section == kDefaultsSection)
        nrows = NUM_DEFAULTS_ROWS;
    else if (section == kAccountsSection)
        nrows = [self.delegate areMoreServicesAvailable] ?
            self.services.count + 1 : self.services.count;

    return nrows;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    NSString * title = nil;

    if (section == kDefaultsSection)
        title = NSLocalizedString(@"photoservicesview.defaults.title", @"");
    else if (section == kAccountsSection)
        title = NSLocalizedString(@"photoservicesview.accounts.title", @"");

    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"PhotoServicesTableViewCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleValue1
            reuseIdentifier:CellIdentifier]
            autorelease];

    if (indexPath.section == kDefaultsSection) {
        NSString * label = nil;
        NSString * detail = nil;
        BOOL canSelect = NO;

        if (indexPath.row == kPhotoDefaults) {
            label =
                NSLocalizedString(@"photoservicesview.photoservice.label", @"");
            detail = [self.delegate currentlySelectedPhotoServiceName];
            canSelect = [self.delegate canSelectPhotoService];
        } else if (indexPath.row == kVideoDefaults) {
            label =
                NSLocalizedString(@"photoservicesview.videoservice.label", @"");
            detail = [self.delegate currentlySelectedVideoServiceName];
            canSelect = [self.delegate canSelectVideoService];
        }

        if (!detail)
            detail =
                NSLocalizedString(@"photoserviceview.service.notselected", @"");

        cell.textLabel.text = label;
        cell.detailTextLabel.text = detail;
        if (canSelect) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else if (indexPath.section == kAccountsSection)
        if (indexPath.row == self.services.count) {
            cell.textLabel.text =
                NSLocalizedString(@"photoservices.addaccount.label", @"");
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        } else {
            PhotoServiceCredentials * psc =
                [self.services objectAtIndex:indexPath.row];
            cell.textLabel.text = [psc serviceName];
            cell.detailTextLabel.text = [psc accountDisplayName];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kDefaultsSection) {
        if (indexPath.row == kPhotoDefaults) {
            if ([self.delegate canSelectPhotoService])
                [self.delegate selectServiceForPhotos];
        } else if (indexPath.row == kAccountsSection) {
            if ([self.delegate canSelectVideoService])
                [self.delegate selectServiceForVideos];
        }
    } else if (indexPath.section == kAccountsSection)
        if (indexPath.row == self.services.count)  // adding a new account
            [self.delegate userWantsToAddNewPhotoService:self.credentials];
        else
            [self.delegate userWantsToEditAccountAtIndex:indexPath.row
                                             credentials:self.credentials];
}

@end
