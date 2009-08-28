//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "EditTextViewController.h"

@interface EditTextViewController ()

@property (nonatomic, retain) UITableViewCell * textFieldCell;
@property (nonatomic, retain) UITextField * textField;

@end

@implementation EditTextViewController

@synthesize delegate;
@synthesize textFieldCell, textField;
@synthesize viewTitle;

- (void)dealloc
{
    self.delegate = nil;

    self.textFieldCell = nil;
    self.textField = nil;

    self.viewTitle = nil;

    [super dealloc];
}

- (id)initWithDelegate:(id<EditTextViewControllerDelegate>)aDelegate
{
    if (self = [super initWithNibName:@"EditTextView" bundle:nil])
        self.delegate = aDelegate;

    return self;
}

#pragma mark UIViewController overrides

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.title = self.viewTitle;
    [self.textField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.delegate userDidSetText:self.textField.text];
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
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.textFieldCell;
}

@end
