//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendsDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "Trend.h"

typedef enum
{
    kCurrentTrends,
    kDailyTrends,
    kWeeklyTrends
} TrendType;

@interface TrendsDisplayMgr ()

@property (nonatomic, retain) TwitterService * service;

@property (nonatomic, retain) NetworkAwareViewController *
    networkAwareViewController;
@property (nonatomic, retain) TrendsViewController * trendsViewController;
@property (nonatomic, retain) UISegmentedControl * segmentedControl;

@property (nonatomic, retain) NSMutableArray * allTrends;

- (void)fetchTrends:(TrendType)trendType;

- (void)showTrends:(NSArray *)trends;
- (void)showError:(NSError *)error;

@end

@implementation TrendsDisplayMgr

@synthesize service, networkAwareViewController, trendsViewController;
@synthesize segmentedControl, allTrends;

#pragma mark Initialization

- (void)dealloc
{
    self.service = nil;
    self.networkAwareViewController = nil;
    self.trendsViewController = nil;
    self.segmentedControl = nil;
    self.allTrends = nil;
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
          netAwareController:(NetworkAwareViewController *)navc
{
    if (self = [super init]) {
        self.service = aService;
        self.service.delegate = self;

        self.networkAwareViewController = navc;
        self.networkAwareViewController.delegate = self;
        self.networkAwareViewController.targetViewController =
            self.trendsViewController;

        self.segmentedControl = (UISegmentedControl *)
            self.networkAwareViewController.navigationItem.titleView;
        [self.segmentedControl addTarget:self
                                  action:@selector(filterChanged:)
                        forControlEvents:UIControlEventValueChanged];
        

        self.allTrends = [NSMutableArray arrayWithObjects:
            [NSNull null], [NSNull null], [NSNull null], nil];

        UIBarButtonItem * refreshButton =
            self.networkAwareViewController.navigationItem.leftBarButtonItem;
        refreshButton.target = self;
        refreshButton.action = @selector(refresh);
    }

    return self;
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSInteger selectedTrend = self.segmentedControl.selectedSegmentIndex;
    NSArray * cachedTrends = [allTrends objectAtIndex:selectedTrend];
    if ([cachedTrends isEqual:[NSNull null]]) {
        [self fetchTrends:selectedTrend];
        [self.networkAwareViewController setCachedDataAvailable:NO];
        [self.networkAwareViewController
            setUpdatingState:kConnectedAndUpdating];
    } else {
        [self.trendsViewController updateWithTrends:cachedTrends];
        [self.networkAwareViewController setCachedDataAvailable:YES];
        [self.networkAwareViewController
            setUpdatingState:kConnectedAndNotUpdating];
    }
}

#pragma mark Responding to the view changing

- (void)filterChanged:(id)sender
{
    NSInteger selectedTrend = self.segmentedControl.selectedSegmentIndex;
    NSArray * cachedTrends = [allTrends objectAtIndex:selectedTrend];
    if ([cachedTrends isEqual:[NSNull null]]) {
        [self.trendsViewController updateWithTrends:[NSArray array]];
        [self.networkAwareViewController setCachedDataAvailable:NO];
        [self.networkAwareViewController
            setUpdatingState:kConnectedAndUpdating];
        [self fetchTrends:selectedTrend];
    } else {
        [self.trendsViewController updateWithTrends:cachedTrends];
        [self.networkAwareViewController
            setUpdatingState:kConnectedAndNotUpdating];
        [self.networkAwareViewController setCachedDataAvailable:YES];
    }
}

- (void)refresh
{
    NSInteger selectedTrend = self.segmentedControl.selectedSegmentIndex;
    [self fetchTrends:selectedTrend];
    [self.networkAwareViewController setUpdatingState:kConnectedAndUpdating];
}

#pragma mark TrendsViewControllerDelegate implementation

- (void)userDidSelectTrend:(Trend *)trend
{
    //NSString * searchTerms = trend.searchTerms;
    //[self.searchDisplayMgr displaySearchResults:trend];
}

#pragma mark Fetch trends

- (void)fetchTrends:(TrendType)trendType
{
    switch (trendType) {
        case kCurrentTrends:
            NSLog(@"Fetching current trends.");
            [self.service fetchCurrentTrends];
            break;
        case kDailyTrends:
            NSLog(@"Fetching daily trends.");
            [self.service fetchDailyTrends];
            break;
        case kWeeklyTrends:
            NSLog(@"Fetching weekly trends.");
            [self.service fetchWeeklyTrends];
            break;
    }
}

#pragma mark TwitterServiceDelegate implementation

- (void)fetchedCurrentTrends:(NSArray *)trends
{
    [self.allTrends replaceObjectAtIndex:kCurrentTrends withObject:trends];
    if (kCurrentTrends == self.segmentedControl.selectedSegmentIndex)
        [self showTrends:trends];
}

- (void)failedToFetchCurrentTrends:(NSError *)error
{
    [self showError:error];
    [self.networkAwareViewController setUpdatingState:kConnectedAndNotUpdating];
    [self.networkAwareViewController setCachedDataAvailable:
        ![[self.allTrends objectAtIndex:kCurrentTrends] isEqual:[NSNull null]]];
}

- (void)fetchedDailyTrends:(NSArray *)trends
{
    [self.allTrends replaceObjectAtIndex:kDailyTrends withObject:trends];
    if (kDailyTrends == self.segmentedControl.selectedSegmentIndex)
        [self showTrends:trends];
}

- (void)failedToFetchDailyTrends:(NSError *)error
{
    [self showError:error];
    [self.networkAwareViewController setUpdatingState:kConnectedAndNotUpdating];
    [self.networkAwareViewController setCachedDataAvailable:
        ![[self.allTrends objectAtIndex:kDailyTrends] isEqual:[NSNull null]]];
}

- (void)fetchedWeeklyTrends:(NSArray *)trends
{
    [self.allTrends replaceObjectAtIndex:kWeeklyTrends withObject:trends];
    if (kWeeklyTrends == self.segmentedControl.selectedSegmentIndex)
        [self showTrends:trends];
}

- (void)failedToFetchWeeklyTrends:(NSError *)error
{
    [self showError:error];
    [self.networkAwareViewController setUpdatingState:kConnectedAndNotUpdating];
    [self.networkAwareViewController setCachedDataAvailable:
        ![[self.allTrends objectAtIndex:kWeeklyTrends] isEqual:[NSNull null]]];
}

#pragma mark UI helpers

- (void)showTrends:(NSArray *)trends
{
    [self.trendsViewController updateWithTrends:trends];
    [self.networkAwareViewController setUpdatingState:kConnectedAndNotUpdating];
    [self.networkAwareViewController setCachedDataAvailable:YES];
    
}

- (void)showError:(NSError *)error
{
    NSString * title = NSLocalizedString(@"trends.fetch.failed", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
    
}

#pragma mark Accessors

- (TrendsViewController *)trendsViewController
{
    if (!trendsViewController) {
        trendsViewController = [[TrendsViewController alloc]
            initWithNibName:@"TrendsView" bundle:nil];
        trendsViewController.delegate = self;
    }

    return trendsViewController;
}

@end
