//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "BitlyLogInViewController.h"
#import "UIButton+StandardButtonAdditions.h"
#import "SettingsReader.h"
#import "TwitbitShared.h"

@interface BitlyLogInViewController ()
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * apiKey;

- (void)syncInterfaceToState;
@end

@implementation BitlyLogInViewController

@synthesize username, apiKey;
@synthesize delegate/*, displayMode*/;
@synthesize /*displayingActivity,*/ editingExistingAccount;

- (void)dealloc
{
    self.delegate = nil;

    self.username = nil;
    self.apiKey = nil;

    [saveButton release];
    [cancelButton release];

    [usernameCell release];
    [apiKeyCell release];

    [usernameTextField release];
    [apiKeyTextField release];

    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername apiKey:(NSString *)anApiKey
{
    if (self = [super initWithNibName:@"BitlyLogInView" bundle:nil]) {
        self.username = aUsername;
        self.apiKey = anApiKey;
    }

    return self;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = LS(@"bitlyloginview.title");
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;
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
    return NSLocalizedString(@"bitlyloginview.footer", @"");
}

// Customize the appearance of table view cells.

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row == 0 ? usernameCell : apiKeyCell;
}

#pragma mark Button actions

- (IBAction)save:(id)sender
{
    [self.delegate userDidSave:usernameTextField.text
                        apiKey:apiKeyTextField.text];
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
        [apiKeyTextField becomeFirstResponder];
    } else {
        self.username = usernameTextField.text;
        self.apiKey = apiKeyTextField.text;
        [self.delegate userDidSave:self.username apiKey:self.apiKey];
    }

    return YES;
}

#pragma mark Private implementation

- (void)syncInterfaceToState
{
    usernameTextField.text = self.username;
    apiKeyTextField.text = self.apiKey;

    saveButton.enabled = self.username.length > 0 && self.apiKey.length > 0;
    if (self.editingExistingAccount) {
        NSString * title = LS(@"bitlyloginview.deleteaccount.button.title");
        UIButton * deleteButton = [UIButton deleteButtonWithTitle:title];
        [deleteButton addTarget:self
                         action:@selector(deleteAccount:)
               forControlEvents:UIControlEventTouchUpInside];
        self.tableView.tableFooterView = deleteButton;
        [deleteButton release];  // delete button is returned with retain count
                                 // of 1 (should be autoreleased)
    } else
        self.tableView.tableFooterView = nil;
}

- (void)deleteAccount:(id)sender
{
    NSString * title = nil;
    NSString * cancelButtonTitle =
        LS(@"bitlyloginview.deleteaccount.confirm.cancel");
    NSString * destructiveButtonTitle =
        LS(@"bitlyloginview.deleteaccount.confirm.delete");

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
        NSLog(@"Deleting Bitly account: %@.", self.username);
       [self.delegate deleteAccount:self.username];
    }

    [actionSheet autorelease];
}

@end
