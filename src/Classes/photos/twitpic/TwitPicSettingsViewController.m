//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicSettingsViewController.h"
#import "TwitPicCredentials+KeychainAdditions.h"
#import "UIButton+StandardButtonAdditions.h"

@interface TwitPicSettingsViewController ()

@property (nonatomic, retain) UIBarButtonItem * saveButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, retain) UITableViewCell * usernameCell;
@property (nonatomic, retain) UITableViewCell * passwordCell;

@property (nonatomic, retain) UITextField * usernameTextField;
@property (nonatomic, retain) UITextField * passwordTextField;

@property (nonatomic, retain) UIButton * deleteButton;

- (void)syncInterfaceWithState;

@end

@implementation TwitPicSettingsViewController

@synthesize delegate;
@synthesize saveButton, cancelButton;
@synthesize usernameCell, passwordCell;
@synthesize usernameTextField, passwordTextField;
@synthesize deleteButton;
@synthesize credentials;

- (void)dealloc
{
    self.saveButton = nil;
    self.cancelButton = nil;

    self.usernameCell = nil;
    self.passwordCell = nil;

    self.usernameTextField = nil;
    self.passwordTextField = nil;

    self.deleteButton = nil;

    self.credentials = nil;

    [super dealloc];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;

    self.tableView.tableFooterView = self.deleteButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self syncInterfaceWithState];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return self.usernameCell;
    else if (indexPath.row == 1)
        return self.passwordCell;

    return nil;
}

#pragma mark Button actions

- (IBAction)userDidSave:(id)sender
{
}

- (IBAction)userDidCancel:(id)sender
{
}

- (void)deleteService:(id)sender
{
    [self.delegate deleteServiceWithCredentials:self.credentials];
}

#pragma Private implementation

- (void)syncInterfaceWithState
{
    self.usernameTextField.text = self.credentials.username;
    self.passwordTextField.text = [self.credentials password];

    self.saveButton.enabled =
        self.credentials.username.length && [self.credentials password].length;
}

#pragma mark Accessors

- (UIButton *)deleteButton
{
    if (!deleteButton) {
        deleteButton = [[UIButton deleteButtonWithTitle:@"Delete"] retain];
        [deleteButton addTarget:self
                         action:@selector(deleteService:)
               forControlEvents:UIControlEventTouchUpInside];
    }

    return deleteButton;
}


@end
