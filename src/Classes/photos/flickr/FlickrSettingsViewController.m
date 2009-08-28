//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrSettingsViewController.h"
#import "UIButton+StandardButtonAdditions.h"

static const NSInteger NUM_SECTIONS = 2;
enum {
    kAccountDetailsSection,
    kAccountSettingsSection
};

static const NSInteger NUM_ACCOUNT_DETAILS_ROWS = 3;
enum {
    kUsernameRow,
    kFullNameRow,
    kUserIdRow
};

static const NSInteger NUM_ACCOUNT_SETTINGS_ROWS = 1;
enum {
    kTagsRow
};

@interface FlickrSettingsViewController ()

- (UITableViewCell *)tableView:(UITableView *)tv
    cellInstanceForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation FlickrSettingsViewController

@synthesize delegate, credentials;

- (void)dealloc
{
    self.delegate = nil;

    self.credentials = nil;

    [super dealloc];
}

- (id)initWithDelegate:(id<FlickrSettingsViewControllerDelegate>)aDelegate
{
    if (self = [super initWithNibName:@"FlickrSettingsView" bundle:nil])
        self.delegate = aDelegate;

    return self;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"flickrsettingsview.title", @"");

    NSString * deleteButtonTitle =
        NSLocalizedString(@"flickrsettingsview.delete", @"");
    UIButton * deleteButton =
        [UIButton deleteButtonWithTitle:deleteButtonTitle];
    [deleteButton addTarget:self
                     action:@selector(deleteService:)
           forControlEvents:UIControlEventTouchUpInside];

    self.tableView.tableFooterView = deleteButton;
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

    switch (section) {
        case kAccountDetailsSection:
            nrows = NUM_ACCOUNT_DETAILS_ROWS;
            break;
        case kAccountSettingsSection:
            nrows = NUM_ACCOUNT_SETTINGS_ROWS;
            break;
    }

    return nrows;
}

- (NSString *)tableView:(UITableView *)tv
    titleForHeaderInSection:(NSInteger)section
{
    NSString * title = nil;

    switch (section) {
        case kAccountDetailsSection:
            title = NSLocalizedString(@"flickrsettingsview.details.title", @"");
            break;
        case kAccountSettingsSection:
            title =
                NSLocalizedString(@"flickrsettingsview.settings.title", @"");
            break;
    }

    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell =
        [self tableView:tv cellInstanceForRowAtIndexPath:indexPath];

    if (indexPath.section == kAccountDetailsSection) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;

        if (indexPath.row == kUsernameRow) {
            cell.detailTextLabel.text = self.credentials.username;
            cell.textLabel.text =
                NSLocalizedString(@"flickrsettingsview.username.label", @"");
        } else if (indexPath.row == kFullNameRow) {
            cell.detailTextLabel.text = self.credentials.fullName;
            cell.textLabel.text =
                NSLocalizedString(@"flickrsettingsview.fullname.label", @"");
        } else if (indexPath.row == kUserIdRow) {
            cell.detailTextLabel.text = self.credentials.userId;
            cell.textLabel.text =
                NSLocalizedString(@"flickrsettingsview.userid.label", @"");
        }
    } else if (indexPath.section == kAccountSettingsSection) {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        cell.textLabel.text =
            NSLocalizedString(@"flickrsettingsview.tags.label", @"");
    }

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAccountSettingsSection) {
        if (indexPath.row == kTagsRow)
            [self.delegate userWantsToSelectTags:self.credentials];
    }
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)  // delete button was pressed
      [self.delegate deleteServiceWithCredentials:self.credentials];

    [actionSheet autorelease];
}

#pragma mark Button actions

- (void)deleteService:(id)sender
{
    // the sheet is autoreleased in the delegate method

    NSString * title =
        NSLocalizedString(@"flickrsettingsview.delete.alert.title", @"");
    NSString * cancelButtonTitle =
        NSLocalizedString(@"flickrsettingsview.delete.alert.cancel.title", @"");
    NSString * destructiveButtonTitle =
        NSLocalizedString(@"flickrsettingsview.delete.alert.delete.title", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc] initWithTitle:title
                                    delegate:self
                           cancelButtonTitle:cancelButtonTitle
                      destructiveButtonTitle:destructiveButtonTitle
                           otherButtonTitles:nil];

    // HACK: Display the sheet in the key window so will appear over the tab
    // bar. Even though the sheet is always visible over the tab bar, the
    // portion of the sheet on top of the tab bar does not respond touch events.
    [sheet showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark Private implementation

- (UITableViewCell *)tableView:(UITableView *)tv
    cellInstanceForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier = indexPath.section == kAccountDetailsSection ?
        @"FlickrDetailsTableViewCell" : @"FlickrSettingsTableViewCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:identifier];

    if (cell == nil) {
        if (indexPath.section == kAccountDetailsSection)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleValue2
                reuseIdentifier:identifier] autorelease];
        else if (indexPath.section == kAccountSettingsSection)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:identifier] autorelease];
    }

    return cell;
}

@end
