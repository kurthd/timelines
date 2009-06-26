//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchViewController.h"

@interface SearchViewController ()

@property (nonatomic, copy) NSArray * searchResults;

@end

@implementation SearchViewController

@synthesize delegate, searchResults;

- (void)dealloc
{
    self.delegate = nil;
    self.searchResults = nil;
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
    return self.searchResults.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"SearchResultCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[UITableViewCell alloc]
              initWithFrame:CGRectZero reuseIdentifier:CellIdentifier]
             autorelease];

    id searchResult = [self.searchResults objectAtIndex:indexPath.row];
    cell.textLabel.text = [searchResult description];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id searchResult = [self.searchResults objectAtIndex:indexPath.row];
    [self.delegate userDidSelectSearchResult:searchResult];
}

#pragma mark Updating the display

- (void)updateWithSearchResults:(NSArray *)someSearchResults
{
    self.searchResults = someSearchResults;
    [self.tableView reloadData];
}

@end
