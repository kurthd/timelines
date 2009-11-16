//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ListsViewController.h"
#import "TwitterList.h"
#import "RotatableTabBarController.h"
#import "TwitterListCell.h"

@interface ListsViewController ()

@property (nonatomic, copy) NSDictionary * lists;
@property (nonatomic, copy) NSDictionary * subscriptions;
@property (nonatomic, copy) NSArray * sortedListCache;
@property (nonatomic, copy) NSArray * sortedSubscriptionCache;

- (NSArray *)sortedLists;
- (NSArray *)sortedSubscriptions;

@end

@implementation ListsViewController

@synthesize delegate;
@synthesize lists, subscriptions;
@synthesize sortedListCache, sortedSubscriptionCache;

- (void)dealloc
{
    [lists release];
    [subscriptions release];
    [sortedListCache release];
    [sortedSubscriptionCache release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.view.frame =
           [[RotatableTabBarController instance] landscape] ?
           CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.frame =
        [[RotatableTabBarController instance] landscape] ?
        CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);

    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self sortedLists] count] > 0 &&
        [[self sortedSubscriptions] count] > 0 ?
        2 : 1;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section
{
    NSString * sectionTitle = nil;

    BOOL twoSections =
        [[self sortedLists] count] > 0 &&
        [[self sortedSubscriptions] count] > 0;

    if (twoSections) {
        sectionTitle =
            section == 0 ?
            NSLocalizedString(@"listsviewcontroller.sections.lists", @"") :
            NSLocalizedString(
            @"listsviewcontroller.sections.subscriptions", @"");
    }

    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows =
        section == 0 ?
        [[self sortedLists] count] : [[self sortedSubscriptions] count];

    return numRows;
}

#pragma mark UITableViewDelegate implementation

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * cellIdentifier = @"TwitterListCell";

    TwitterListCell * cell =
        (TwitterListCell *)
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell =
            [[[TwitterListCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:cellIdentifier]
            autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    BOOL subscription =
        indexPath.section == 1 || [[self sortedLists] count] == 0;

    TwitterList * list =
        subscription ?
        [[self sortedSubscriptions] objectAtIndex:indexPath.row] :
        [[self sortedLists] objectAtIndex:indexPath.row];

    [cell setList:list];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL subscription =
        indexPath.section == 1 || [[self sortedLists] count] == 0;

    TwitterList * list =
        subscription ?
        [[self sortedSubscriptions] objectAtIndex:indexPath.row] :
        [[self sortedLists] objectAtIndex:indexPath.row];

    [delegate userDidSelectListWithId:list.identifier];
}

#pragma mark Public implementation

- (void)setLists:(NSDictionary *)someLists
    subscriptions:(NSDictionary *)someSubscriptions
    pagesShown:(NSUInteger)pagesShown
{
    self.lists = someLists;
    self.subscriptions = someSubscriptions;

    self.sortedListCache = nil;
    self.sortedSubscriptionCache = nil;

    [self.tableView reloadData];
}

- (NSArray *)sortedLists
{
    if (!self.sortedListCache)
        self.sortedListCache =
            [[self.lists allValues]
            sortedArrayUsingSelector:@selector(compare:)];

    return self.sortedListCache;
}

- (NSArray *)sortedSubscriptions
{
    if (!self.sortedSubscriptionCache)
        self.sortedSubscriptionCache =
            [[self.subscriptions allValues]
            sortedArrayUsingSelector:@selector(compare:)];

    return self.sortedSubscriptionCache;
}

@end
