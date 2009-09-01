//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "InstapaperLogInViewController.h"

@implementation InstapaperLogInViewController

@synthesize delegate, credentials, displayMode, displayingActivity;

- (void)dealloc
{
    self.delegate = nil;

    [saveButton release];
    [cancelButton release];
    [activityButton release];

    [usernameCell release];
    [passwordCell release];

    [usernameTextField release];
    [passwordTextField release];

    [deleteButton release];

    [credentials release];

    [super dealloc];
}

- (id)initWithDelegate:(id<InstapaperLogInViewControllerDelegate>)aDelegate
{
    if (self = [super initWithNibName:@"InstapaperLogInView" bundle:nil])
        self.delegate = aDelegate;

    return self;
}

#pragma mark Public interface

- (void)displayActivity
{
    [self.navigationItem setRightBarButtonItem:activityButton animated:YES];
    usernameTextField.enabled = NO;
    passwordTextField.enabled = NO;
    [usernameTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];

    displayingActivity = YES;
}

- (void)hideActivity
{
    [self.navigationItem setRightBarButtonItem:saveButton animated:YES];
    usernameTextField.enabled = YES;
    passwordTextField.enabled = YES;
    [usernameTextField becomeFirstResponder];

    displayingActivity = NO;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"instapaperloginview.title", @"");
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;

    UIActivityIndicatorView * ai =
        [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [ai startAnimating];
    activityButton = [[UIBarButtonItem alloc] initWithCustomView:ai];
    [ai release];

    displayingActivity = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    saveButton.enabled = usernameTextField.text.length > 0;
    [usernameTextField becomeFirstResponder];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(@"instapaperloginview.footer", @"");
}

// Customize the appearance of table view cells.

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row == 0 ? usernameCell : passwordCell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController =
    //     [[AnotherViewController alloc]
    //      initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
}

#pragma mark Button actions

- (IBAction)save:(id)sender
{
    [self.delegate userDidSave:usernameTextField.text
                      password:passwordTextField.text];
}

- (IBAction)cancel:(id)sender
{
    [self.delegate userDidCancel];
}

#pragma mark UITextFieldDelegate implementation

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string
{
    if (textField == usernameTextField) {
        NSString * s = usernameTextField.text;
        s = [s stringByReplacingCharactersInRange:range withString:string];
        saveButton.enabled = s.length > 0;
    }

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    saveButton.enabled = !(textField == usernameTextField);
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == usernameTextField) {
        [usernameTextField resignFirstResponder];
        [passwordTextField becomeFirstResponder];
    } else {
        NSString * username = usernameTextField.text;
        NSString * password = passwordTextField.text;
        [self.delegate userDidSave:username password:password];
    }

    return YES;
}

@end
