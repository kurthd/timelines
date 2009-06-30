//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ExplainOauthViewController.h"
#import "UIColor+TwitchColors.h"

@interface ExplainOauthViewController ()

@property (nonatomic, retain) UITableView * tableView;

@property (nonatomic, retain) UITableViewCell * activeCell;
@property (nonatomic, retain) UITableViewCell * buttonCell;
@property (nonatomic, retain) UITableViewCell * activityCell;
@property (nonatomic, retain) UITableViewCell * authorizingCell;

@property (nonatomic, retain) UINavigationBar * navigationBar;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@end

@implementation ExplainOauthViewController

@synthesize delegate, tableView;
@synthesize activeCell, buttonCell, activityCell, authorizingCell;
@synthesize navigationBar, cancelButton;
@synthesize allowsCancel;

- (void)dealloc
{
    self.delegate = nil;
    self.tableView = nil;
    self.activeCell = nil;
    self.buttonCell = nil;
    self.activityCell = nil;
    self.authorizingCell = nil;
    self.navigationBar = nil;
    self.cancelButton = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor twitchBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showButtonView];
}

- (void)userDidCancel
{
    [self.delegate userDidCancelExplanation];
}

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

#pragma mark Table view methods

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

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"explainoauth.header", @"");
    
}

- (NSString *)tableView:(UITableView *)tableView
    titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(@"explainoauth.footer", @"");
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.activeCell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.activeCell.selectionStyle != UITableViewCellSelectionStyleNone) {
        [self.delegate beginAuthorization];
        [[self.tableView cellForRowAtIndexPath:indexPath] setSelected:NO
                                                             animated:YES];
    }
}

#pragma mark Accessors

- (void)setAllowsCancel:(BOOL)doesAllowCancel
{
    allowsCancel = doesAllowCancel;

    self.navigationBar.topItem.leftBarButtonItem =
        allowsCancel ? self.cancelButton : nil;
}

@end
