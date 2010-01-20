//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountSettingsViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "InstapaperCredentials.h"
#import "UIApplication+ConfigurationAdditions.h"


NSInteger pushNotificationSoundSort(PushNotificationSound * sound1,
                                    PushNotificationSound * sound2,
                                    void * context)
{
    return [sound1.name compare:sound2.name];
}


static const NSInteger NUM_SECTIONS = 2;
enum {
    kPushNotificationSection,
    kIntegrationSection
};

static const NSInteger NUM_PUSH_NOTIFICATION_ROWS = 3;
enum {
    kMentionsRow,
    kDirectMessagesRow,
    kNotificationSoundRow
};

static const NSInteger NUM_INTEGRATION_ROWS = 2; // don't show bitly for now
enum {
    kPhotAndVideoRow,
    kInstapaperRow,
    kBitlyRow
};

@interface AccountSettingsViewController ()

@property (nonatomic, retain) UITableViewCell * pushMentionsCell;
@property (nonatomic, retain) UITableViewCell * pushDirectMessagesCell;
@property (nonatomic, retain) UITableViewCell * pushNotificationSoundCell;

@property (nonatomic, retain) UISwitch * pushMentionsSwitch;
@property (nonatomic, retain) UISwitch * pushDirectMessagesSwitch;

@property (nonatomic, copy) NSArray * pushSettingTableViewCells;

@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, copy) AccountSettings * settings;

@property (nonatomic, retain) SelectionViewController * soundSelector;

@property (nonatomic, copy) NSArray * pushNotificationSounds;

@property (nonatomic, retain) SoundPlayer * soundPlayer;

- (void)syncDisplayWithSettings;
- (NSInteger)effectiveSectionForSection:(NSInteger)section;

@end

@implementation AccountSettingsViewController

@synthesize delegate;
@synthesize pushMentionsCell, pushDirectMessagesCell, pushNotificationSoundCell;
@synthesize pushMentionsSwitch, pushDirectMessagesSwitch;
@synthesize pushSettingTableViewCells;
@synthesize credentials, settings;
@synthesize soundSelector;
@synthesize pushNotificationSounds;
@synthesize soundPlayer;

- (void)dealloc
{
    self.delegate = nil;

    self.pushMentionsCell = nil;
    self.pushDirectMessagesCell = nil;
    self.pushNotificationSoundCell = nil;

    self.pushMentionsSwitch = nil;
    self.pushDirectMessagesSwitch = nil;

    self.pushSettingTableViewCells = nil;

    self.credentials = nil;
    self.settings = nil;

    self.soundSelector = nil;

    self.pushNotificationSounds = nil;

    self.soundPlayer = nil;

    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    pushSettingTableViewCells =
        [[NSArray alloc] initWithObjects:
        pushMentionsCell, pushDirectMessagesCell, pushNotificationSoundCell,
        nil];
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

    [delegate userDidCommitSettings:self.settings forAccount:self.credentials];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return [[UIApplication sharedApplication] isLiteVersion] ?
        NUM_SECTIONS - 1 : NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    NSString * title = nil;
    section = [self effectiveSectionForSection:section];

    if (section == kPushNotificationSection)
        title = NSLocalizedString(@"accountsettings.push.header", @"");
    else if (section == kIntegrationSection)
        title = NSLocalizedString(@"accountsettings.integration.header", @"");

    return title;
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger nrows = 0;
    section = [self effectiveSectionForSection:section];

    if (section == kPushNotificationSection)
        nrows = NUM_PUSH_NOTIFICATION_ROWS;
    else if (section == kIntegrationSection)
        nrows = NUM_INTEGRATION_ROWS;

    return nrows;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;
    NSInteger section = [self effectiveSectionForSection:indexPath.section];

    if (section == kPushNotificationSection)
        cell = [self.pushSettingTableViewCells objectAtIndex:indexPath.row];
    else if (section == kIntegrationSection &&
        indexPath.row == kPhotAndVideoRow) {
        static NSString * CellIdentifier = @"AccountSettingsPhotoTableViewCell";

        cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier]
                autorelease];


        cell.textLabel.text =
            NSLocalizedString(@"accountsettings.photo.integration.label", @"");

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else if (section == kIntegrationSection &&
        indexPath.row == kInstapaperRow) {
        static NSString * CellIdentifier =
            @"AccountSettingsIntegrationTableViewCell";

        cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleValue1
                reuseIdentifier:CellIdentifier]
                autorelease];

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
    } else if (section == kIntegrationSection &&
        indexPath.row == kBitlyRow) {
        static NSString * CellIdentifier =
            @"AccountSettingsIntegrationTableViewCell";

        cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell)
            cell =
                [[[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleValue1
                reuseIdentifier:CellIdentifier]
                autorelease];

        cell.textLabel.text =
            NSLocalizedString(
            @"accountsettings.integration.bitly.label", @"");

        // TODO: add bitlyCredentials to credentials
        id bitlyCreds = nil;
        cell.detailTextLabel.text =
            bitlyCreds ?
            /* bitlyCreds.username */ @"" :
            NSLocalizedString(
            @"accountsettings.integration.bitly.notconfigured.label",
            @"");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [self effectiveSectionForSection:indexPath.section];

    if (section == kPushNotificationSection) {
        if (indexPath.row == kNotificationSoundRow) {
            // HACK: just push the sound selector here; I'm too lazy at this
            // point to bother passing it through the display manager
            [self.navigationController pushViewController:self.soundSelector
                                                 animated:YES];
        }
    } else if (section == kIntegrationSection) {
        if (indexPath.row == kPhotAndVideoRow)
            [self.delegate
                userWantsToConfigurePhotoServicesForAccount:self.credentials];
        else if (indexPath.row == kInstapaperRow)
            [self.delegate
                userWantsToConfigureInstapaperForAccount:self.credentials];
        else if (indexPath.row == kBitlyRow)
            [self.delegate
                userWantsToConfigureBitlyForAccount:self.credentials];
    }
}

#pragma mark SelectionViewControllerDelegate implementation

- (NSArray *)allChoices:(SelectionViewController *)controller
{
    return self.pushNotificationSounds;
}

- (NSInteger)initialSelectedIndex:(SelectionViewController *)controller
{
    PushNotificationSound * sound = [settings pushNotificationSound];

    NSInteger selectedIndex = 0;
    for (NSInteger i = 0; i < self.pushNotificationSounds.count; ++i) {
        PushNotificationSound * pns =
            [self.pushNotificationSounds objectAtIndex:i];
        if ([pns.name isEqualToString:sound.name]) {
            selectedIndex = i;
            break;
        }
    }

    return selectedIndex;
}

- (void)selectionViewController:(SelectionViewController *)controller
       userDidSelectItemAtIndex:(NSInteger)index
{
    PushNotificationSound * sound =
        [self.pushNotificationSounds objectAtIndex:index];
    NSLog(@"Selected sound: %@", sound);

    // play the sound
    [self.soundPlayer
        performSelectorInBackground:@selector(playSoundInMainBundle:)
                         withObject:sound.file];

    // save the new setting
    [settings setPushNotificationSound:sound];

    [self.delegate userDidCommitSettings:settings forAccount:credentials];
}

#pragma mark Public interface implementation

- (void)presentSettings:(AccountSettings *)someSettings
             forAccount:(TwitterCredentials *)someCredentials
{
    self.settings = someSettings;
    self.credentials = someCredentials;

    [self syncDisplayWithSettings];

    self.navigationItem.title = credentials.username;
    [self.tableView reloadData];
    // this forces the tableview to scroll to top
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
}

- (void)reloadDisplay
{
    [self.tableView reloadData];
    [self syncDisplayWithSettings];
}

#pragma mark Display helpers

- (void)syncDisplayWithSettings
{
    [pushMentionsSwitch setOn:[settings pushMentions] animated:NO];
    [pushDirectMessagesSwitch setOn:[settings pushDirectMessages] animated:NO];

    self.pushNotificationSoundCell.detailTextLabel.text =
        [settings pushNotificationSound].name;
}

- (NSInteger)effectiveSectionForSection:(NSInteger)section
{
    return [[UIApplication sharedApplication] isLiteVersion] ?
        kIntegrationSection : section;
}

#pragma mark Accessors

- (UITableViewCell *)pushNotificationSoundCell
{
    if (!pushNotificationSoundCell) {
        pushNotificationSoundCell =
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleValue1
          reuseIdentifier:@"pushNotificationSoundCell"];
        pushNotificationSoundCell.textLabel.text =
            LS(@"accountsettings.push.sound.label");
        pushNotificationSoundCell.accessoryType =
            UITableViewCellAccessoryDisclosureIndicator;
    }

    return pushNotificationSoundCell;
}

- (SelectionViewController *)soundSelector
{
    if (!soundSelector) {
        soundSelector =
            [[SelectionViewController alloc] initWithNibName:@"SelectionView"
                                                      bundle:nil];
        soundSelector.viewTitle =
            LS(@"accountsettings.push.sound.selector.title");
        soundSelector.delegate = self;
    }

    return soundSelector;
}

- (NSArray *)pushNotificationSounds
{
    if (!pushNotificationSounds) {
        NSMutableSet * sounds =
            [[PushNotificationSound systemSounds] mutableCopy];

        PushNotificationSound * defaultSound =
            [PushNotificationSound defaultSound];

        for (PushNotificationSound * sound in sounds)
            if ([defaultSound.name isEqualToString:sound.name]) {
                [sounds removeObject:sound];
                break;
            }

        NSArray * tmp = [sounds allObjects];
        NSMutableArray * sortedSounds =
            [[tmp sortedArrayUsingFunction:pushNotificationSoundSort
                                   context:NULL] mutableCopy];

        [sortedSounds insertObject:defaultSound atIndex:0];
        pushNotificationSounds = sortedSounds;

        [sounds release];
    }

    return pushNotificationSounds;
}

- (SoundPlayer *)soundPlayer
{
    if (!soundPlayer)
        soundPlayer = [[SoundPlayer alloc] init];

    return soundPlayer;
}

@end
