//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendsViewController.h"

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

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell =
            [[[UITableViewCell alloc]
              initWithFrame:CGRectZero reuseIdentifier:CellIdentifier]
             autorelease];
    }

    cell.textLabel.text =
        [[self.trends objectAtIndex:indexPath.row] description];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id trend = [self.trends objectAtIndex:indexPath.row];
    [self.delegate userDidSelectTrend:trend];
}

#pragma mark Updating the display

- (void)updateWithTrends:(NSArray *)newTrends
{
    self.trends = newTrends;
    [self.tableView reloadData];
}

@end
