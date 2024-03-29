//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "LogInViewController.h"
#import "UIColor+TwitchColors.h"

static const int NUM_SECTIONS = 1;
enum Sections
{
    kCredentialsSection
};

static const int NUM_CREDENTIAL_ROWS = 2;
enum CredentialRows
{
    kUsernameRow,
    kPasswordRow
};

@interface LogInViewController ()

@property (nonatomic, retain) UINavigationBar * navigationBar;
@property (nonatomic, retain) UITableView * tableView;

@property (nonatomic, retain) UIBarButtonItem * logInButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@property (nonatomic, retain) UITableViewCell * usernameCell;
@property (nonatomic, retain) UITableViewCell * passwordCell;

@property (nonatomic, retain) UITextField * usernameTextField;
@property (nonatomic, retain) UITextField * passwordTextField;

- (void)resetForm;
- (void)enableForm;
- (void)disableForm;

@end

@implementation LogInViewController

@synthesize delegate;
@synthesize navigationBar, tableView;
@synthesize logInButton, cancelButton;
@synthesize usernameCell, passwordCell;
@synthesize usernameTextField, passwordTextField;
@synthesize title, footer;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationBar = nil;
    self.tableView = nil;

    self.logInButton = nil;
    self.cancelButton = nil;

    self.usernameCell = nil;
    self.passwordCell = nil;

    self.usernameTextField = nil;
    self.passwordTextField = nil;

    self.title = nil;
    self.footer = nil;

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.logInButton.enabled = NO;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationBar.topItem.title = self.title;

    [self resetForm];
    self.cancelButton.enabled = [delegate userCanCancel];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger nrows = 0;

    switch (section) {
        case kCredentialsSection:
            nrows = NUM_CREDENTIAL_ROWS;
            break;
    }

    return nrows;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section
{
    return section == kCredentialsSection ? self.footer : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kCredentialsSection:
            switch (indexPath.row) {
                case kUsernameRow:
                    return self.usernameCell;
                case kPasswordRow:
                    return self.passwordCell;
            }
            break;
    }

    return nil;
}

#pragma mark UITextFieldDelegate implementation

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string
{
    NSString * username = self.usernameTextField.text;
    NSString * password = self.passwordTextField.text;

    if (textField == self.usernameTextField)
        username = [username stringByReplacingCharactersInRange:range
                                                     withString:string];
    else if (textField == self.passwordTextField)
        password = [password stringByReplacingCharactersInRange:range
                                                     withString:string];

    logInButton.enabled = [self.delegate isUsernameValid:username] &&
        username.length && password.length;

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    logInButton.enabled = NO;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
        return YES;
    } else if (textField == self.passwordTextField) {
        NSString * username = self.usernameTextField.text;
        NSString * password = self.passwordTextField.text;

        if (username.length && password.length) {
            [self userDidSave:self];
            return YES;
        }
    }

    return NO;
}

- (void)promptForLogIn
{
    [self enableForm];
    self.logInButton.enabled =
        self.usernameTextField.text.length > 0 &&
        self.passwordTextField.text.length > 0;
    [self.usernameTextField becomeFirstResponder];
}

- (void)promptForLoginWithUsername:(NSString *)username editable:(BOOL)editable
{
    [self enableForm];
    self.logInButton.enabled =
        self.usernameTextField.text.length > 0 &&
        self.passwordTextField.text.length > 0;
    self.usernameTextField.text = username;
    self.usernameTextField.enabled = editable;
    [self.passwordTextField becomeFirstResponder];
}

#pragma mark Handling user actions

- (IBAction)userDidSave:(id)sender
{
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    [self disableForm];

    [delegate userDidProvideUsername:self.usernameTextField.text
                            password:self.passwordTextField.text];
}

- (IBAction)userDidCancel:(id)sender
{
    [delegate userDidCancel];
}

#pragma mark Helper functions

- (void)resetForm
{
    self.usernameTextField.text = @"";
    self.passwordTextField.text = @"";
}

- (void)enableForm
{
    self.logInButton.enabled = YES;
    self.cancelButton.enabled = [delegate userCanCancel];

    self.usernameTextField.enabled = YES;
    self.passwordTextField.enabled = YES;
}

- (void)disableForm
{
    self.logInButton.enabled = NO;
    //self.cancelButton.enabled = NO;

    self.usernameTextField.enabled = NO;
    self.passwordTextField.enabled = NO;
}

@end
