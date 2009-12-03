//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendsViewController.h"
#import "WhatTheTrendService.h"
#import "NetworkAwareViewController.h"
#import "TrendsTableViewCell.h"

@interface TrendsViewController ()
@property (nonatomic, retain) WhatTheTrendService * service;
@property (nonatomic, copy) NSArray * trends;

- (void)refreshTrends;
@end

@implementation TrendsViewController

@synthesize service, trends, netController;

- (void)dealloc
{
    self.service = nil;
    self.trends = nil;
    self.netController = nil;

    [super dealloc];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem * refreshButton =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                             target:self
                             action:@selector(refreshTrends)];
    self.netController.navigationItem.rightBarButtonItem = refreshButton;
    [refreshButton release];

    [self refreshTrends];
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

#pragma mark WhatTheTrendServiceDelegate implementation

- (void)service:(WhatTheTrendService *)svc didFetchTrends:(NSArray *)trnds
{
    self.trends = trnds;

    [self.netController setUpdatingState:kConnectedAndNotUpdating];
    [self.netController setCachedDataAvailable:YES];

    [self.tableView reloadData];
}

- (void)service:(WhatTheTrendService *)svc failedToFetchTrends:(NSError *)e
{
    NSLog(@"Failed to fetch trends: %@", e);
}

#pragma mark Private implementation

- (void)refreshTrends
{
    [self.netController setUpdatingState:kConnectedAndUpdating];
    [self.netController setCachedDataAvailable:!!self.trends];

    [self.service fetchCurrentTrends];
}

#pragma mark Accessors

- (WhatTheTrendService *)service
{
    if (!service) {
        service = [[WhatTheTrendService alloc] init];
        service.delegate = self;
    }

    return service;
}

@end

