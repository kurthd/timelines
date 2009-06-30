//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ExplainOauthViewController.h"
#import "UIColor+TwitchColors.h"

@interface ExplainOauthViewController ()

@property (nonatomic, retain) UITableView * tableView;
@property (nonatomic, retain) UITableViewCell * authorizationCell;
@property (nonatomic, retain) UIView * buttonView;
@property (nonatomic, retain) UIView * activityView;
@property (nonatomic, retain) UIView * authorizingView;
@property (nonatomic, retain) UINavigationBar * navigationBar;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;

@end

@implementation ExplainOauthViewController

@synthesize delegate, tableView;
@synthesize authorizationCell, buttonView, activityView, authorizingView;
@synthesize navigationBar, cancelButton;
@synthesize allowsCancel;

- (void)dealloc
{
    self.delegate = nil;
    self.tableView = nil;
    self.authorizationCell = nil;
    self.buttonView = nil;
    self.activityView = nil;
    self.authorizingView = nil;
    self.navigationBar = nil;
    self.cancelButton = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showButtonView];
    self.tableView.backgroundColor = [UIColor twitchBackgroundColor];
}

- (void)userDidCancel
{
    [self.delegate userDidCancelExplanation];
}

- (void)showActivityView
{
    [self.buttonView removeFromSuperview];
    [self.authorizingView removeFromSuperview];

    [self.authorizationCell.contentView addSubview:self.activityView];
    self.authorizationCell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)showButtonView
{
    [self.activityView removeFromSuperview];
    [self.authorizingView removeFromSuperview];

    [self.authorizationCell.contentView addSubview:self.buttonView];
    self.authorizationCell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (void)showAuthorizingView
{
    [self.activityView removeFromSuperview];
    [self.buttonView removeFromSuperview];

    [self.authorizationCell.contentView addSubview:self.authorizingView];
    self.authorizationCell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    return self.authorizationCell;

    static NSString * CellIdentifier = @"Cell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell =
            [[[UITableViewCell alloc]
              initWithFrame:CGRectZero reuseIdentifier:CellIdentifier]
             autorelease];
    }

    cell.textLabel.text = NSLocalizedString(@"explainoauth.begin", @"");
    cell.textLabel.textAlignment = UITextAlignmentCenter;

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate beginAuthorization];
    [[self.tableView cellForRowAtIndexPath:indexPath]
        setSelected:NO animated:YES];
}

#pragma mark Accessors

- (void)setAllowsCancel:(BOOL)doesAllowCancel
{
    allowsCancel = doesAllowCancel;

    self.navigationBar.topItem.leftBarButtonItem =
        allowsCancel ? self.cancelButton : nil;
}

@end
