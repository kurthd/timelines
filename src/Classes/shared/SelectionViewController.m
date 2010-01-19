//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SelectionViewController.h"
#import "UIColor+TwitchColors.h"

@interface SelectionViewController ()

@property (nonatomic, copy) NSArray * choices;

+ (void)configureSelectedCell:(UITableViewCell *)cell;
+ (void)configureNormalCell:(UITableViewCell *)cell;

@end

@implementation SelectionViewController

@synthesize delegate, viewTitle, choices, selectedIndex;

- (void)dealloc
{
    self.delegate = nil;
    self.viewTitle = nil;
    self.choices = nil;

    [super dealloc];
}

#pragma mark UIViewController overrides

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.title = self.viewTitle;

    self.choices = [self.delegate allChoices:self];
    selectedIndex = [self.delegate initialSelectedIndex:self];
    [self.tableView reloadData];
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
    return self.choices.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"SelectionTableVeiwCell";

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:CellIdentifier] autorelease];

    cell.textLabel.text =
        [[self.choices objectAtIndex:indexPath.row] description];
    if (indexPath.row == selectedIndex)
        [[self class] configureSelectedCell:cell];
    else
        [[self class] configureNormalCell:cell];

    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * oldIndexPath = [NSIndexPath indexPathForRow:selectedIndex
                                                    inSection:0];
    UITableViewCell * oldCell = [tv cellForRowAtIndexPath:oldIndexPath];
    [[self class] configureNormalCell:oldCell];

    UITableViewCell * newCell = [tv cellForRowAtIndexPath:indexPath];
    [[self class] configureSelectedCell:newCell];

    selectedIndex = indexPath.row;
    [self.delegate selectionViewController:self
                  userDidSelectItemAtIndex:selectedIndex];

    [tv deselectRowAtIndexPath:indexPath animated:YES];
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

@end
