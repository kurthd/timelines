//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendsViewController.h"
#import "GenericTrendExplanationService.h"
#import "NetworkAwareViewController.h"
#import "TrendsTableViewCell.h"
#import "RotatableTabBarController.h"

@interface TrendsViewController ()
@property (nonatomic, retain) GenericTrendExplanationService * service;
@property (nonatomic, copy) NSArray * trends;
@property (nonatomic, readonly) UIBarButtonItem * updatingTrendsActivityView;
- (void)refreshTrends;
@end

@implementation TrendsViewController

@synthesize service, trends, netController;
@synthesize selectionTarget, selectionAction;
@synthesize explanationTarget, explanationAction;
@synthesize refreshButton;

- (void)dealloc
{
    self.service = nil;
    self.trends = nil;
    self.netController = nil;

    self.selectionTarget = nil;
    self.explanationTarget = nil;

    self.refreshButton = nil;
    [updatingTrendsActivityView release];

    [super dealloc];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    refreshButton =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                             target:self
                             action:@selector(refreshTrends)];
    self.netController.navigationItem.rightBarButtonItem = refreshButton;

    [self refreshTrends];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.frame =
        [[RotatableTabBarController instance] landscape] ?
        CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);

    BOOL landscape = [[RotatableTabBarController instance] landscape];
    if (landscape != lastDisplayedInLandscape)
        [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    lastDisplayedInLandscape = [[RotatableTabBarController instance] landscape];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return self.trends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * ReuseIdentifier = @"TrendsTableViewCell";

    TrendsTableViewCell * cell = (TrendsTableViewCell *)
        [self.tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (!cell)
        cell =
            [[[TrendsTableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:ReuseIdentifier] autorelease];

    Trend * trend = [self.trends objectAtIndex:indexPath.row];
    [cell setTitle:trend.name];
    [cell setExplanation:trend.explanation];
    
    BOOL landscape = [RotatableTabBarController instance].landscape;
    [cell setLandscape:landscape];

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Trend * trend = [self.trends objectAtIndex:indexPath.row];

    return [TrendsTableViewCell heightForTitle:trend.name
                                   explanation:trend.explanation];
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectionTarget && self.selectionAction) {
        Trend * trend = [self.trends objectAtIndex:indexPath.row];
        [self.selectionTarget performSelector:self.selectionAction
                                   withObject:trend];
    }
}

- (void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    Trend * trend = [self.trends objectAtIndex:indexPath.row];
    [self.explanationTarget performSelector:self.explanationAction
                                 withObject:trend];
}

#pragma mark GenericTrendExplanationServiceDelegate implementation

- (void)service:(GenericTrendExplanationService *)svc didFetchTrends:(NSArray *)trnds
{
    self.trends = trnds;

    [self.netController.navigationItem setRightBarButtonItem:self.refreshButton
        animated:YES];
    [self.netController setCachedDataAvailable:YES];

    [self.tableView reloadData];
    [self.tableView flashScrollIndicators];
}

- (void)service:(GenericTrendExplanationService *)svc failedToFetchTrends:(NSError *)e
{
    NSLog(@"Failed to fetch trends: %@", e);
}

#pragma mark Private implementation

- (void)refreshTrends
{
    if (!!self.trends)
        [self.netController.navigationItem
            setRightBarButtonItem:[self updatingTrendsActivityView]
            animated:YES];
    [self.netController setCachedDataAvailable:!!self.trends];

    [self.service fetchCurrentTrends];
}

#pragma mark Accessors

- (GenericTrendExplanationService *)service
{
    if (!service) {
        service = [[GenericTrendExplanationService letsBeTrendsService] retain];
        service.delegate = self;
    }

    return service;
}

- (UIBarButtonItem *)updatingTrendsActivityView
{
    if (!updatingTrendsActivityView) {
        NSString * backgroundImageFilename =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            @"NavigationButtonBackgroundDarkTheme.png" :
            @"NavigationButtonBackground.png";
        UIView * view =
            [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:backgroundImageFilename]];
        UIActivityIndicatorView * activityView =
            [[[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]
            autorelease];
        activityView.frame = CGRectMake(7, 5, 20, 20);
        [view addSubview:activityView];

        updatingTrendsActivityView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [activityView startAnimating];

        [view release];
    }

    return updatingTrendsActivityView;
}

@end
