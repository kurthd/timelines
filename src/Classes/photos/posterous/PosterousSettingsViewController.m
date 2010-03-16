//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PosterousSettingsViewController.h"
#import "PosterousCredentials+KeychainAdditions.h"
#import "TwitbitShared.h"

@interface PosterousSettingsViewController ()

@property (nonatomic, retain) UIBarButtonItem * saveButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, retain) UITableViewCell * usernameCell;
@property (nonatomic, retain) UITableViewCell * passwordCell;

@property (nonatomic, retain) UITextField * usernameTextField;
@property (nonatomic, retain) UITextField * passwordTextField;

@property (nonatomic, retain) UIButton * deleteButton;

- (void)syncInterfaceWithState;

@end

@implementation PosterousSettingsViewController

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

#pragma mark Public implementation

- (void)enable
{
    self.usernameTextField.enabled = YES;
    self.passwordTextField.enabled = YES;

    self.cancelButton.enabled = YES;
    self.saveButton.enabled = YES;

    self.deleteButton.enabled = YES;

    enabled = YES;
}

- (void)disable
{
    self.usernameTextField.enabled = NO;
    self.passwordTextField.enabled = NO;

    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    self.cancelButton.enabled = NO;
    self.saveButton.enabled = NO;

    self.deleteButton.enabled = NO;

    enabled = NO;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = LS(@"posteroussettings.view.title");

    self.navigationItem.leftBarButtonItem = self.cancelButton;
    self.navigationItem.rightBarButtonItem = self.saveButton;

    self.tableView.tableFooterView = self.deleteButton;

    enabled = YES;
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

#pragma mark UITextFieldDelegate implementation

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string
{
    NSString * s = [textField.text stringByReplacingCharactersInRange:range
                                                           withString:string];

    NSString * username = nil, * password = nil;
    if (textField == self.usernameTextField) {
        username = s;
        password = self.passwordTextField.text;
    } else {
        username = self.usernameTextField.text;
        password = s;
    }

    self.saveButton.enabled = username.length && password.length;

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.saveButton.enabled = NO;

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField)
        [self.passwordTextField becomeFirstResponder];
    else
        [self.passwordTextField resignFirstResponder];

    return YES;
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

- (IBAction)userDidSave:(id)sender
{
    NSString * username = self.usernameTextField.text;
    NSString * password = self.passwordTextField.text;

    [self.delegate userDidSaveUsername:username password:password];
}

- (IBAction)userDidCancel:(id)sender
{
    [self.delegate userDidCancel];
}

- (void)deleteService:(id)sender
{
    // the sheet is autoreleased in the delegate method

    NSString * title = LS(@"posteroussettingsview.delete.alert.title");
    NSString * cancelButtonTitle =
        LS(@"posteroussettingsview.delete.alert.cancel.title");
    NSString * destructiveButtonTitle =
        LS(@"posteroussettingsview.delete.alert.delete.title");

    UIActionSheet * sheet =
        [[UIActionSheet alloc] initWithTitle:title
                                    delegate:self
                           cancelButtonTitle:cancelButtonTitle
                      destructiveButtonTitle:destructiveButtonTitle
                           otherButtonTitles:nil];

    // HACK: Display the sheet in the key window so will appear over the tab
    // bar./ Even though the sheet is always visible over the tab bar, the
    // portion of the sheet on top of the tab bar does not respond touch events.
    [sheet showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma Private implementation

- (void)syncInterfaceWithState
{
    self.usernameTextField.text = self.credentials.username;
    self.passwordTextField.text = [self.credentials password];

    self.saveButton.enabled =
        enabled &&
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
