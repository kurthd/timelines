//
//  Copyright 2010 High Order Bit, Inc. All rights reserved.
//

#import "TimelineSelectionViewController.h"
#import "UIColor+TwitchColors.h"
#import "TwitterList.h"

@interface TimelineSelectionViewController ()

@property (nonatomic, copy) NSDictionary * lists;
@property (nonatomic, copy) NSDictionary * subscriptions;
@property (nonatomic, copy) NSArray * sortedListCache;
@property (nonatomic, copy) NSArray * sortedSubscriptionCache;

- (NSArray *)sortedLists;
- (NSArray *)sortedSubscriptions;
- (NSString *)listNameAtRow:(NSInteger)row;

@end

@implementation TimelineSelectionViewController

@synthesize delegate;
@synthesize lists, subscriptions;
@synthesize sortedListCache, sortedSubscriptionCache;

- (void)viewDidLoad
{
    self.tableView.separatorColor =
        [UIColor colorWithRed:.32 green:.32 blue:.32 alpha:1];
    self.tableView.backgroundColor = [UIColor defaultDarkThemeCellColor];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return 4 + [self sortedLists].count + [self sortedSubscriptions].count;
}

- (UITableViewCell *)tableView:(UITableView *)tv
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"UITableViewCell";
    UITableViewCell * cell =
        [tv dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier]
            autorelease];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSInteger listsRange =
        4 + [self sortedLists].count + [self sortedSubscriptions].count;
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Timeline";
            cell.imageView.image = [UIImage imageNamed:@"TimelineGlyph.png"];
            break;
        case 1:
            cell.textLabel.text = @"Mentions";
            cell.imageView.image = [UIImage imageNamed:@"MentionsGlyph.png"];
            break;
        case 2:
            cell.textLabel.text = @"Favorites";
            cell.imageView.image = [UIImage imageNamed:@"FavoritesGlyph.png"];
            break;
        case 3:
            cell.textLabel.text = @"Retweets";
            cell.imageView.image = [UIImage imageNamed:@"RetweetsGlyph.png"];
            break;
        default:
            if (indexPath.row < listsRange) {
                cell.textLabel.text = [self listNameAtRow:indexPath.row];
                cell.imageView.image =
                    [UIImage imageNamed:@"ListsGlyph.png"];
            }
            break;
    }
    
    return cell;
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [delegate showTimeline];
            break;
        case 1:
            [delegate showMentions];
            break;
        case 2:
            [delegate showFavorites];
            break;
        case 3:
            [delegate showRetweets];
            break;
    }
}

#pragma mark TimelineSelectionViewController implementation

- (void)setLists:(NSDictionary *)someLists
    subscriptions:(NSDictionary *)someSubscriptions
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

- (NSString *)listNameAtRow:(NSInteger)row
{
    NSString * listNameAtRow = nil;
    
    if (row < 4 + [self sortedLists].count) {
        TwitterList * listAtRow = [[self sortedLists] objectAtIndex:row - 4];
        listNameAtRow = listAtRow.name;
    } else {
        TwitterList * listAtRow =
            [[self sortedSubscriptions]
            objectAtIndex:row - 4 - [self sortedLists].count];
        listNameAtRow =
            [listAtRow.fullName stringByReplacingOccurrencesOfString:@"@"
            withString:@""];
    }
    
    return listNameAtRow;
}

@end
