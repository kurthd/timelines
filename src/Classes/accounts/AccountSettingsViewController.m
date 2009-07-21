//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountSettingsViewController.h"

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
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"accountsettings.push.header", @"");
    
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(@"accountsettings.push.footer", @"");
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return pushSettingTableViewCells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell =
        [self.pushSettingTableViewCells objectAtIndex:indexPath.row];
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
