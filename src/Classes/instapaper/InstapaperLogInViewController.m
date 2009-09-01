//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "InstapaperLogInViewController.h"
#import "InstapaperCredentials+KeychainAdditions.h"
#import "UIButton+StandardButtonAdditions.h"

@interface InstapaperLogInViewController ()

- (void)syncInterfaceToState;

@end

@implementation InstapaperLogInViewController

@synthesize delegate, credentials, displayMode;
@synthesize displayingActivity, editingExistingAccount;

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
    editingExistingAccount = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    saveButton.enabled = usernameTextField.text.length > 0;

    // if we don't do this after a delay, we don't see the animation and
    // the view transition animations looks like they're skipping
    [usernameTextField performSelector:@selector(becomeFirstResponder)
                            withObject:nil
                            afterDelay:0.5];

    [self syncInterfaceToState];
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

#pragma mark Private implementation

- (void)syncInterfaceToState
{
    usernameTextField.text = credentials.username;
    passwordTextField.text = [credentials password];

    saveButton.enabled = credentials.username.length > 0;

    if (editingExistingAccount) {
        NSString * title =
            NSLocalizedString(@"instapaperloginview.deleteaccount.button.title",
            @"");
        UIButton * deleteButton = [UIButton deleteButtonWithTitle:title];
        [deleteButton addTarget:self
                         action:@selector(deleteAccount:)
               forControlEvents:UIControlEventTouchUpInside];

        self.tableView.tableFooterView = deleteButton;
        [deleteButton release];
    } else
        self.tableView.tableFooterView = nil;
}

- (void)deleteAccount:(id)sender
{
    NSString * title =
        NSLocalizedString(@"instapaperloginview.deleteaccount.confirm.title",
        @"");
    NSString * cancelButtonTitle =
        NSLocalizedString(@"instapaperloginview.deleteaccount.confirm.cancel",
        @"");
    NSString * destructiveButtonTitle =
        NSLocalizedString(@"instapaperloginview.deleteaccount.confirm.delete",
        @"");

    // released in the delegate method
    UIActionSheet * sheet =
        [[UIActionSheet alloc] initWithTitle:title
                                    delegate:self
                           cancelButtonTitle:cancelButtonTitle
                      destructiveButtonTitle:destructiveButtonTitle
                           otherButtonTitles:nil];

    [sheet showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        NSLog(@"Deleting Instapaper account: %@.", self.credentials.username);
        [self.delegate deleteAccount:credentials];
    }

    [actionSheet autorelease];
}

#pragma mark Accessors

- (void)setCredentials:(InstapaperCredentials *)someCredentials
{
    if (credentials != someCredentials) {
        [credentials release];
        credentials = [someCredentials retain];

        [self syncInterfaceToState];
    }
}

- (void)setEditingExistingAccount:(BOOL)editing
{
    if (editing != editingExistingAccount) {
        editingExistingAccount = editing;
        [self syncInterfaceToState];
    }
}

@end
