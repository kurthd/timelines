//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrTagsViewController.h"
#import "UIColor+TwitchColors.h"

@interface FlickrTagsViewController ()

+ (void)configureSelectedCell:(UITableViewCell *)cell;
+ (void)configureNormalCell:(UITableViewCell *)cell;

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

#pragma mark Public implementation

- (void)addSelectedTag:(NSString *)tag
{
    if (![self.tags containsObject:tag]) {
        NSMutableArray * mutableTags = [self.tags mutableCopy];
        [mutableTags addObject:tag];
        self.tags = mutableTags;
        [mutableTags release];
    }

    if (![self.selectedTags containsObject:tag])
        [self selectTag:tag];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    tags = [[NSArray alloc] init];
    selectedTags = [[NSArray alloc] init];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return self.tags.count + 1;
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

    if (indexPath.row == self.tags.count) {
        cell.textLabel.text =
            NSLocalizedString(@"flickrtagsview.addtag.label", @"");
        [[self class] configureNormalCell:cell];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        NSString * tag = [self.tags objectAtIndex:indexPath.row];
        cell.textLabel.text = tag;
        if ([self.selectedTags containsObject:tag])
            [[self class] configureSelectedCell:cell];
        else
            [[self class] configureNormalCell:cell];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.tags.count)
        [self.delegate userWantsToAddTag];
    else {
        NSString * tag = [self.tags objectAtIndex:indexPath.row];
        NSArray * visibleCells = self.tableView.visibleCells;
        UITableViewCell * cell = nil;
        for (UITableViewCell * c in visibleCells)
            if ([c.textLabel.text isEqualToString:tag]) {
                cell = c;
                break;
            }

        if ([self.selectedTags containsObject:tag]) {
            [self unselectTag:tag];
            if (cell)
                [[self class] configureNormalCell:cell];
        } else {
            [self selectTag:tag];
            if (cell)
                [[self class] configureSelectedCell:cell];
        }

        [tv deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark Private implementation

+ (void)configureSelectedCell:(UITableViewCell *)cell
{
    cell.textLabel.textColor = [UIColor twitchCheckedColor];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

+ (void)configureNormalCell:(UITableViewCell *)cell
{
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)selectTag:(NSString *)tag
{
    NSMutableSet * copy = [self.selectedTags mutableCopy];
    [copy addObject:tag];
    [selectedTags release];
    selectedTags = copy;
}

- (void)unselectTag:(NSString *)tag
{
    NSMutableSet * copy = [self.selectedTags mutableCopy];
    [copy removeObject:tag];
    [selectedTags release];
    selectedTags = copy;
}

#pragma mark Accessors

- (void)setTags:(NSArray *)newTags
{
    if (newTags != tags) {
        [tags release];
        tags = [[newTags sortedArrayUsingSelector:@selector(compare:)] retain];

        [self.tableView reloadData];
    }
}

- (void)setSelectedTags:(NSSet *)newSelectedTags
{
    if (selectedTags != newSelectedTags) {
        [selectedTags release];
        selectedTags = [newSelectedTags copy];

        [self.tableView reloadData];
    }
}

@end
