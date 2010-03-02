//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import "XauthLogInViewController.h"
#import "TwitbitShared.h"

@interface XauthLogInViewController ()
@property (nonatomic, retain) UIBarButtonItem * saveButton;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;
@property (nonatomic, retain) UITableViewCell * usernameCell;
@property (nonatomic, retain) UITableViewCell * passwordCell;
@property (nonatomic, retain) UITextField * usernameTextField;
@property (nonatomic, retain) UITextField * passwordTextField;
@end

@implementation XauthLogInViewController

@synthesize delegate;
@synthesize saveButton, cancelButton;
@synthesize usernameCell, passwordCell;
@synthesize usernameTextField, passwordTextField;
@synthesize allowsCancel;

- (void)dealloc
{
    self.delegate = nil;

    self.saveButton = nil;
    self.cancelButton = nil;

    self.usernameCell = nil;
    self.passwordCell = nil;

    self.usernameTextField = nil;
    self.passwordTextField = nil;

    [super dealloc];
}

#pragma mark Public implementation

- (void)displayActivity:(BOOL)activity
{
    self.saveButton.enabled = !activity;
    self.cancelButton.enabled = self.allowsCancel && !activity;

    self.usernameTextField.enabled = !activity;
    self.passwordTextField.enabled = !activity;

    if (!activity)
        [self.usernameTextField becomeFirstResponder];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = LS(@"account.addaccount");
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    self.navigationItem.rightBarButtonItem = self.saveButton;

    self.saveButton.enabled = NO;
    self.cancelButton.enabled = self.allowsCancel;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.usernameTextField becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    return YES;
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row == 0 ? self.usernameCell : self.passwordCell;
}

- (NSString *)tableView:(UITableView *)tableView
titleForFooterInSection:(NSInteger)section
{
    return LS(@"xauthview.footer");
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

    self.saveButton.enabled = [self.delegate isUsernameValid:username] &&
        username.length && password.length;

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.saveButton.enabled = NO;
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

@end

