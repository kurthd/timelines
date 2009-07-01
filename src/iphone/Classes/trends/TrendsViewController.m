//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendsViewController.h"
#import "Trend.h"

@interface TrendsViewController ()

@property (nonatomic, copy) NSArray * trends;

@end

@implementation TrendsViewController

@synthesize delegate;
@synthesize trends;

- (void)dealloc
{
    self.trends = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView flashScrollIndicators];
}

- (void)scrollToTop:(BOOL)animated
{
    NSIndexPath * firstRow = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView scrollToRowAtIndexPath:firstRow
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:animated];
    [self.tableView flashScrollIndicators];
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
    return self.trends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"TrendsTableViewCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[UITableViewCell alloc]
              initWithFrame:CGRectZero reuseIdentifier:CellIdentifier]
             autorelease];

    Trend * trend = [self.trends objectAtIndex:indexPath.row];
    cell.textLabel.text = trend.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Trend * trend = [self.trends objectAtIndex:indexPath.row];
    [self.delegate userDidSelectTrend:trend];
}

#pragma mark Updating the display

- (void)updateWithTrends:(NSArray *)newTrends
{
    self.trends = newTrends;
    [self.tableView reloadData];
}

@end
