//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountSettingsViewController.h"

static const NSInteger NUM_SECTIONS = 2;
enum {
    kPushNotificationSection,
    kPhotoSection
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

#pragma mark Table view methods

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

    return nrows;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;

    if (indexPath.section == kPushNotificationSection)
        cell = [self.pushSettingTableViewCells objectAtIndex:indexPath.row];
    else if (indexPath.section == kPhotoSection) {
        static NSString * CellIdentifier = @"AccountSettingsTableView";

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
    }

    return cell;
}

#pragma mark Public interface to update the display

- (void)presentSettings:(AccountSettings *)someSettings
             forAccount:(TwitterCredentials *)someCredentials
{
    self.settings = someSettings;
    self.credentials = someCredentials;

    [self syncDisplayWithSettings];

    self.navigationItem.title = credentials.username;
}

#pragma mark Display helpers

- (void)syncDisplayWithSettings
{
    [pushMentionsSwitch setOn:[settings pushMentions] animated:NO];
    [pushDirectMessagesSwitch setOn:[settings pushDirectMessages] animated:NO];
}

@end
