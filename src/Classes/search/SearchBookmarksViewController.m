//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchBookmarksViewController.h"
#import "RecentSearch.h"
#import "SavedSearch.h"
#import "Trend.h"
#import "NSDate+StringHelpers.h"
#import "UIAlertView+InstantiationAdditions.h"

typedef enum
{
    kSavedSearchCategory,
    kRecentsCategory,
    kTrendsCategory
} BookmarkCategory;

@interface SearchBookmarksViewController ()

@property (nonatomic, retain) UINavigationBar * navigationBar;

@property (nonatomic, retain) UITableView * tableView;
@property (nonatomic, retain) UISegmentedControl * bookmarkCategorySelector;

@property (nonatomic, retain) UIBarButtonItem * doneButton;
@property (nonatomic, retain) UIBarButtonItem * clearRecentsButton;
@property (nonatomic, retain) UIBarButtonItem * editSavedSearchesButton;
@property (nonatomic, retain) UIBarButtonItem * doneEditingSavedSearchesButton;
@property (nonatomic, retain) UIBarButtonItem * refreshTrendsButton;
@property (nonatomic, retain) UIBarButtonItem * activityButton;
@property (nonatomic, retain) UISegmentedControl * trendsCategorySelector;

@property (nonatomic, copy) NSArray * contents;

- (void)loadDataForCategory:(BookmarkCategory)category;
- (void)displayCategory:(BookmarkCategory)category;

- (void)configureViewForEditingSavedSearches;
- (void)configureViewForNotEditingSavedSearches;

- (UITableViewCell *)createCellForCategory:(BookmarkCategory)category
                           reuseIdentifier:(NSString *)reuseIdentifier;

- (BookmarkCategory)selectedCategory;
- (TrendType)selectedTrendsCategory;

- (void)resetTableView;

- (void)displayActivityView;
- (void)hideActivityView;

@end

@implementation SearchBookmarksViewController

@synthesize delegate;
@synthesize navigationBar;
@synthesize tableView, bookmarkCategorySelector;
@synthesize doneButton;
@synthesize clearRecentsButton;
@synthesize editSavedSearchesButton, doneEditingSavedSearchesButton;
@synthesize refreshTrendsButton, activityButton, trendsCategorySelector;
@synthesize contents;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationBar = nil;

    self.tableView = nil;
    self.bookmarkCategorySelector = nil;

    self.doneButton = nil;
    self.clearRecentsButton = nil;
    self.editSavedSearchesButton = nil;
    self.doneEditingSavedSearchesButton = nil;
    self.refreshTrendsButton = nil;
    self.activityButton = nil;
    self.trendsCategorySelector = nil;

    self.contents = nil;

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.bookmarkCategorySelector addTarget:self
                                      action:@selector(bookmarkCategoryChanged:)
                            forControlEvents:UIControlEventValueChanged];

    [self.trendsCategorySelector addTarget:self
                                    action:@selector(trendsCategoryChanged:)
                          forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BookmarkCategory category = [self selectedCategory];
    [self displayCategory:category];
    [self loadDataForCategory:category];
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
    return contents.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * ReuseIdentifier = @"SearchBookmarksTableViewCell";

    BookmarkCategory category = [self selectedCategory];

    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (cell == nil)
        cell = [self createCellForCategory:category
                           reuseIdentifier:ReuseIdentifier];

    if (category == kTrendsCategory) {
        Trend * trend = [self.contents objectAtIndex:indexPath.row];
        cell.textLabel.text = trend.name;
    } else
        cell.textLabel.text =
            [[self.contents objectAtIndex:indexPath.row] query];

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString * query = [[self.contents objectAtIndex:indexPath.row] query];
    [self.delegate userDidSelectSearchQuery:query];
}

-(BOOL)tableView:(UITableView*)tv
    canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    return self.selectedCategory == kSavedSearchCategory;
}

- (void)tableView:(UITableView *)tv
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSAssert([self selectedCategory] == kSavedSearchCategory,
            @"Only editing of saved searches is supported.");
        NSString * query = [[self.contents objectAtIndex:indexPath.row] query];
        if ([self.delegate removeSavedSearchWithQuery:query]) {
            // delete from the contents first -- required by the table view
            NSMutableArray * mutableContents = [self.contents mutableCopy];
            [mutableContents removeObjectAtIndex:indexPath.row];
            self.contents = mutableContents;
            [self.delegate setSavedSearchOrder:self.contents];

            NSArray * row = [NSArray arrayWithObject:indexPath];
            [self.tableView deleteRowsAtIndexPaths:row
                                  withRowAnimation:UITableViewRowAnimationFade];

            // update UI appropriately after swiping-to-delete
            if (self.navigationBar.topItem.leftBarButtonItem ==
                editSavedSearchesButton)
                self.navigationBar.topItem.leftBarButtonItem.enabled =
                    [self.tableView numberOfRowsInSection:0] > 0;
        }
    }
}

- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
           toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray * searches = [self.contents mutableCopy];
    SavedSearch * movedSearch =
        [[searches objectAtIndex:fromIndexPath.row] retain];
    [searches removeObjectAtIndex:fromIndexPath.row];
    [searches insertObject:movedSearch atIndex:toIndexPath.row];
    [movedSearch release];
    self.contents = searches;

    [self.delegate setSavedSearchOrder:self.contents];
}

#pragma mark Receiving trends

- (void)trends:(NSArray *)trends fetchedForType:(TrendType)trendType
{
    if ([self selectedCategory] == kTrendsCategory &&
        [self selectedTrendsCategory] == trendType) {
        self.contents = trends;

        [self resetTableView];
        [self hideActivityView];
    }
}

- (void)failedToFetchTrendsForType:(TrendType)trendType error:(NSError *)error
{
    NSString * title = NSLocalizedString(@"trends.fetch.failed", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

    [self hideActivityView];
}

#pragma mark UI element actions

- (IBAction)done
{
    [self.delegate userDidCancel];
}

- (IBAction)clearRecentSearches
{
    [self.delegate clearRecentSearches];
    [self displayCategory:[self selectedCategory]];
    [self loadDataForCategory:[self selectedCategory]];
}

- (void)bookmarkCategoryChanged:(id)sender
{
    [self displayCategory:[self selectedCategory]];
    [self loadDataForCategory:[self selectedCategory]];
}

- (void)trendsCategoryChanged:(id)sender
{
    TrendType trendType = [self selectedTrendsCategory];
    self.contents = [self.delegate trendsOfType:trendType refresh:NO];

    if (self.contents)
        [self resetTableView];
    else
        [self displayActivityView];
}

- (IBAction)editSavedSearches
{
    [self configureViewForEditingSavedSearches];
}

- (IBAction)doneEditingSavedSearches
{
    [self configureViewForNotEditingSavedSearches];
}

- (IBAction)refreshTrends
{
    TrendType trendType = [self selectedTrendsCategory];
    [self.delegate trendsOfType:trendType refresh:YES];
    [self displayActivityView];
}

#pragma mark Private implementation

- (void)loadDataForCategory:(BookmarkCategory)category
{
    self.contents = nil;
    switch (category) {
        case kSavedSearchCategory:
            self.contents = [self.delegate savedSearches];
            break;
        case kRecentsCategory:
            self.contents = [self.delegate recentSearches];
            break;
        case kTrendsCategory:
            self.contents =
                [self.delegate trendsOfType:[self selectedTrendsCategory]
                                    refresh:NO];
            if (!self.contents)
                [self displayActivityView];

            break;
    }

    [self resetTableView];
}

- (void)displayCategory:(BookmarkCategory)category
{
    switch (category) {
        case kSavedSearchCategory:
            self.navigationBar.topItem.titleView = nil;
            self.navigationBar.topItem.title =
                [self.bookmarkCategorySelector titleForSegmentAtIndex:category];

            self.navigationBar.topItem.prompt =
                NSLocalizedString(@"searchbookmarks.savedsearches.prompt", @"");

            self.navigationBar.topItem.leftBarButtonItem =
                self.editSavedSearchesButton;
            self.navigationBar.topItem.leftBarButtonItem.enabled =
                [self.tableView numberOfRowsInSection:0] > 0;

            break;
        case kRecentsCategory:
            if (self.tableView.editing)
                [self configureViewForNotEditingSavedSearches];

            self.navigationBar.topItem.titleView = nil;
            self.navigationBar.topItem.title =
                [self.bookmarkCategorySelector titleForSegmentAtIndex:category];

            self.navigationBar.topItem.prompt =
                NSLocalizedString(@"searchbookmarks.recents.prompt", @"");

            self.navigationBar.topItem.leftBarButtonItem =
                self.clearRecentsButton;
            self.navigationBar.topItem.leftBarButtonItem.enabled =
                [self.tableView numberOfRowsInSection:0] > 0;

            break;

        case kTrendsCategory:
            if (self.tableView.editing)
                [self configureViewForNotEditingSavedSearches];

            self.navigationBar.topItem.titleView = self.trendsCategorySelector;
            self.navigationBar.topItem.leftBarButtonItem =
                self.refreshTrendsButton;

            self.navigationBar.topItem.prompt =
                NSLocalizedString(@"searchbookmarks.trends.prompt", @"");

            break;
    }
}

- (BookmarkCategory)selectedCategory
{
    return bookmarkCategorySelector.selectedSegmentIndex;
}

- (TrendType)selectedTrendsCategory
{
    return trendsCategorySelector.selectedSegmentIndex;
}

- (UITableViewCell *)createCellForCategory:(BookmarkCategory)category
                           reuseIdentifier:(NSString *)reuseIdentifier
{
    return [[[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault
      reuseIdentifier:reuseIdentifier] autorelease];
}

- (void)configureViewForEditingSavedSearches
{
    [self.tableView setEditing:YES animated:YES];

    [self.navigationBar.topItem
        setLeftBarButtonItem:self.doneEditingSavedSearchesButton
                    animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    self.navigationBar.topItem.prompt =
        NSLocalizedString(@"searchbookmarks.savedsearches.editing.prompt", @"");
}

- (void)configureViewForNotEditingSavedSearches
{
    [self.tableView setEditing:NO animated:YES];
    [self.navigationBar.topItem
        setLeftBarButtonItem:self.editSavedSearchesButton
                    animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:self.doneButton
                                             animated:YES];
    self.navigationBar.topItem.leftBarButtonItem.enabled =
        self.contents.count > 0;

    self.navigationBar.topItem.prompt =
        NSLocalizedString(@"searchbookmarks.savedsearches.prompt", @"");
}

- (void)resetTableView
{
    [self.tableView reloadData];
    if (self.contents && self.contents.count > 0) {
        NSIndexPath * firstRow = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:firstRow
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
    [self.tableView flashScrollIndicators];
}

- (void)displayActivityView
{
    if ([self selectedCategory] == kTrendsCategory)
        self.navigationBar.topItem.leftBarButtonItem = self.activityButton;
}

- (void)hideActivityView
{
    if ([self selectedCategory] == kTrendsCategory)
        self.navigationBar.topItem.leftBarButtonItem = self.refreshTrendsButton;
}

#pragma mark Accessors


- (UIBarButtonItem *)activityButton
{
    if (!activityButton) {
        /*
        UIActivityIndicatorView * view =
            [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        */

        CGRect frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
        UIActivityIndicatorView * view =
            [[UIActivityIndicatorView alloc] initWithFrame:frame];
        [view startAnimating];
        [view sizeToFit];

        view.autoresizingMask =
            UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleRightMargin |
            UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin;

        activityButton = [[UIBarButtonItem alloc] initWithCustomView:view];

        [view release];
    }

    return activityButton;
}

@end
