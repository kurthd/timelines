//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrTagsViewController.h"

@implementation FlickrTagsViewController

@synthesize delegate;
@synthesize tags;

- (void)dealloc
{
    self.delegate = nil;
    self.tags = nil;

    [super dealloc];
}

- (id)initWithDelegate:(id<FlickrTagsViewControllerDelegate>)aDelegate
{
    if (self = [super initWithNibName:@"FlickrTagsView" bundle:nil])
        self.delegate = aDelegate;

    return self;
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
    return self.tags.count;
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
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:CellIdentifier]
            autorelease];
    }

    cell.textLabel.text = [self.tags objectAtIndex:indexPath.row];

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    // AnotherViewController *anotherViewController =
    //     [[AnotherViewController alloc]
    //      initWithNibName:@"AnotherView" bundle:nil];
    // [self.navigationController pushViewController:anotherViewController];
    // [anotherViewController release];
}

#pragma mark Accessors

- (void)setTags:(NSArray *)newTags
{
    if (newTags != tags) {
        [tags release];
        tags = [newTags copy];

        [self.tableView reloadData];
    }
}

@end
