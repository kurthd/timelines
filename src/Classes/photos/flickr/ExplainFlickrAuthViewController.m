//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ExplainFlickrAuthViewController.h"

@interface ExplainFlickrAuthViewController ()

@property (nonatomic, retain) UITableViewCell * activeCell;
@property (nonatomic, retain) UITableViewCell * buttonCell;
@property (nonatomic, retain) UITableViewCell * activityCell;
@property (nonatomic, retain) UITableViewCell * authorizingCell;

@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@end

@implementation ExplainFlickrAuthViewController

@synthesize delegate;
@synthesize activeCell, buttonCell, activityCell, authorizingCell;
@synthesize cancelButton;

- (void)dealloc
{
    self.delegate = nil;

    self.activeCell = nil;
    self.buttonCell = nil;
    self.activityCell = nil;
    self.authorizingCell = nil;

    self.cancelButton = nil;

    [super dealloc];
}

- (id)initWithDelegate:(id<ExplainFlickrAuthViewControllerDelegate>)aDelegate
{
    if (self = [super initWithNibName:@"ExplainFlickrAuthView" bundle:nil])
        self.delegate = aDelegate;

    return self;
}

#pragma mark Public implementation

- (void)showActivityView
{
    self.activeCell = self.activityCell;
    [self.tableView reloadData];
}

- (void)showButtonView
{
    self.activeCell = self.buttonCell;
    [self.tableView reloadData];
}

- (void)showAuthorizingView
{
    self.activeCell = self.authorizingCell;
    [self.tableView reloadData];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"explainflickrauthview.title", @"");
    self.navigationItem.leftBarButtonItem = self.cancelButton;

    self.activeCell = self.buttonCell;
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tv
    titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"explainflickrauthview.header", @"");
}

- (NSString *)tableView:(UITableView *)tv
    titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(@"explainflickrauthview.footer", @"");
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return activeCell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.activeCell.selectionStyle != UITableViewCellSelectionStyleNone) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        // give the deselection animation an opportunity to do its thing
        // before we call the delegate method, which will trigger the table
        // view to be reloaded and cancel any animations
        [(NSObject *)self.delegate performSelector:@selector(beginAuthorization)
                                        withObject:nil
                                        afterDelay:0.3];
    }
}

#pragma mark Button actions

- (IBAction)userDidCancel
{
    [self.delegate userDidCancelExplanation];
}

@end
