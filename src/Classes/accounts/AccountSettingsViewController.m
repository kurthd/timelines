//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountSettingsViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "InstapaperCredentials.h"

static const NSInteger NUM_SECTIONS = 3;
enum {
    kPushNotificationSection,
    kPhotoSection,
    kIntegrationSection
};

static const NSInteger NUM_PUSH_NOTIFICATION_ROWS = 2;
enum {
    kMentionsRow,
    kDirectMessagesRow
};

static const NSInteger NUM_PHOTO_ROWS = 2;
enum {
    kIntegrationRow,
    kCompressionRow
};

static const NSInteger NUM_INTEGRATION_ROWS = 1;
enum {
    kInstapaperRow
};

@interface AccountSettingsViewController ()

@property (nonatomic, retain) UITableViewCell * pushMentionsCell;
@property (nonatomic, retain) UITableViewCell * pushDirectMessagesCell;

@property (nonatomic, retain) UISwitch * pushMentionsSwitch;
@property (nonatomic, retain) UISwitch * pushDirectMessagesSwitch;

@property (nonatomic, copy) NSArray * pushSettingTableViewCells;

@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, copy) AccountSettings * settings;

- (void)syncDisplayWithSettings;

@end

@implementation AccountSettingsViewController

@synthesize delegate;
@synthesize pushMentionsCell, pushDirectMessagesCell;
@synthesize pushMentionsSwitch, pushDirectMessagesSwitch;
@synthesize pushSettingTableViewCells;
@synthesize credentials, settings;

- (void)dealloc
{
    self.delegate = nil;

    self.pushMentionsCell = nil;
    self.pushDirectMessagesCell = nil;

    self.pushMentionsSwitch = nil;
    self.pushDirectMessagesSwitch = nil;

    self.pushSettingTableViewCells = nil;

    self.credentials = nil;
    self.settings = nil;

    [super dealloc];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    pushSettingTableViewCells =
        [[NSArray alloc] initWithObjects:
        pushMentionsCell, pushDirectMessagesCell, nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self syncDisplayWithSettings];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.settings setPushMentions:self.pushMentionsSwitch.on];
    [self.settings setPushDirectMessages:self.pushDirectMessagesSwitch.on];

    [delegate userDidCommitSettings:self.settings
                         forAccount:self.credentials];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    NSString * title = nil;

    if (section == kPushNotificationSection)
        title = NSLocalizedString(@"accountsettings.push.header", @"");
    else if (section == kPhotoSection)
        title = NSLocalizedString(@"accountsettings.photo.header", @"");
    else if (section == kIntegrationSection)
        title = NSLocalizedString(@"accountsettings.integration.header", @"");

    return title;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section
{
    NSString * footer = nil;

    if (section == kPushNotificationSection)
        footer = NSLocalizedString(@"accountsettings.push.footer", @"");

    return footer;
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger nrows = 0;

    if (section == kPushNotificationSection)
        nrows = NUM_PUSH_NOTIFICATION_ROWS;
    else if (section == kPhotoSection)
        nrows = NUM_PHOTO_ROWS;
    else if (section == kIntegrationSection)
        nrows = NUM_INTEGRATION_ROWS;

    return nrows;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;

    if (indexPath.section == kPushNotificationSection)
        cell = [self.pushSettingTableViewCells objectAtIndex:indexPath.row];
    else if (indexPath.section == kPhotoSection) {
        static NSString * CellIdentifier = @"AccountSettingsPhotoTableViewCell";

        cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier]
                autorelease];

        if (indexPath.row == kIntegrationRow)
            cell.textLabel.text =
                NSLocalizedString(
                @"accountsettings.photo.integration.label", @"");
        else if (indexPath.row == kCompressionRow)
            cell.textLabel.text =
                NSLocalizedString(
                @"accountsettings.photo.compression.label", @"");

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else if (indexPath.section == kIntegrationSection) {
        static NSString * CellIdentifier =
            @"AccountSettingsIntegrationTableViewCell";

        cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleValue1
                reuseIdentifier:CellIdentifier]
                autorelease];

        if (indexPath.row == kInstapaperRow) {
            cell.textLabel.text =
                NSLocalizedString(
                @"accountsettings.integration.instapaper.label", @"");

            InstapaperCredentials * ic =
                self.credentials.instapaperCredentials;
            cell.detailTextLabel.text =
                ic ?
                ic.username :
                NSLocalizedString(
                @"accountsettings.integration.instapaper.notconfigured.label",
                @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kPhotoSection)
        if (indexPath.row == kIntegrationRow)
            [self.delegate
                userWantsToConfigurePhotoServicesForAccount:self.credentials];
        else {
            [[UIAlertView simpleAlertViewWithTitle:@"Not Implemented"
                                           message:nil] show];
            [self.tableView deselectRowAtIndexPath:indexPath
                                          animated:YES];
        }
    else if (indexPath.section == kIntegrationSection)
        [self.delegate
            userWantsToConfigureInstapaperForAccount:self.credentials];
}

#pragma mark Public interface implementation

- (void)presentSettings:(AccountSettings *)someSettings
             forAccount:(TwitterCredentials *)someCredentials
{
    self.settings = someSettings;
    self.credentials = someCredentials;

    [self syncDisplayWithSettings];

    self.navigationItem.title = credentials.username;
}

- (void)reloadDisplay
{
    [self syncDisplayWithSettings];
    [self.tableView reloadData];
}

#pragma mark Display helpers

- (void)syncDisplayWithSettings
{
    [pushMentionsSwitch setOn:[settings pushMentions] animated:NO];
    [pushDirectMessagesSwitch setOn:[settings pushDirectMessages] animated:NO];
}

@end
