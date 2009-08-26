//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrTagsViewController.h"
#import "UIColor+TwitchColors.h"

@interface FlickrTagsViewController ()

- (void)configureSelectedCell:(UITableViewCell *)cell;
- (void)configureNormalCell:(UITableViewCell *)cell;

- (void)selectTag:(NSString *)tag;
- (void)unselectTag:(NSString *)tag;

@end

@implementation FlickrTagsViewController

@synthesize delegate;
@synthesize tags, selectedTags;

- (void)dealloc
{
    self.delegate = nil;

    self.tags = nil;
    self.selectedTags = nil;

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

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return self.tags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:CellIdentifier]
            autorelease];

    NSString * tag = [self.tags objectAtIndex:indexPath.row];
    cell.textLabel.text = tag;
    if ([self.selectedTags containsObject:tag])
        [self configureSelectedCell:cell];
    else
        [self configureNormalCell:cell];

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * tag = [self.tags objectAtIndex:indexPath.row];
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([self.selectedTags containsObject:tag]) {
        [self unselectTag:tag];
        [self configureNormalCell:cell];
    } else {
        [self selectTag:tag];
        [self configureSelectedCell:cell];
    }
}

#pragma mark Private implementation

- (void)configureSelectedCell:(UITableViewCell *)cell
{
    cell.textLabel.textColor = [UIColor twitchCheckedColor];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)configureNormalCell:(UITableViewCell *)cell
{
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)selectTag:(NSString *)tag
{
    NSMutableSet * copy = [self.selectedTags mutableCopy];
    [copy addObject:tag];
    self.selectedTags = copy;
    [copy release];
}

- (void)unselectTag:(NSString *)tag
{
    NSMutableSet * copy = [self.selectedTags mutableCopy];
    [copy removeObject:tag];
    self.selectedTags = copy;
    [copy release];
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

- (void)setSelectedTags:(NSSet *)newSelectedTags
{
    if (selectedTags != newSelectedTags) {
        [selectedTags release];
        tags = [newSelectedTags copy];

        [self.tableView reloadData];
    }
}

@end
