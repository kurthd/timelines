//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserListTableViewController.h"
#import "UserSummaryTableViewCell.h"
#import "User.h"
#import "AsynchronousNetworkFetcher.h"
#import "User+UIAdditions.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"
#import "TwitbitShared.h"

@interface User (Sorting)
- (NSComparisonResult)compare:(User *)user;
@end

@implementation User (Sorting)
- (NSComparisonResult)compare:(User *)user
{
    NSNumber * myId =
        [NSNumber numberWithLongLong:[self.identifier longLongValue]];
    NSNumber * theirId =
        [NSNumber numberWithLongLong:[user.identifier longLongValue]];

    return [myId compare:theirId];
}
@end

#define ROW_HEIGHT 48

@interface UserListTableViewController ()

- (UIImage *)getAvatarForUser:(User *)user;
- (NSArray *)sortedUsers;

+ (UIImage *)defaultAvatar;

+ (UIColor *)lightCellColor;
+ (UIColor *)darkCellColor;

@end

@implementation UserListTableViewController

static UIImage * defaultAvatar;

@synthesize delegate, sortedUserCache;

- (void)dealloc
{
    [footerView release];
    [currentPagesLabel release];
    [loadMoreButton release];
    [loadingMoreIndicator release];
    [noMorePagesLabel release];

    [users release];
    [alreadySent release];

    [sortedUserCache release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.tableFooterView = footerView;

    alreadySent = [[NSMutableDictionary dictionary] retain];
    
    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.tableView.separatorColor = [UIColor twitchGrayColor];
        self.view.backgroundColor = [UIColor defaultDarkThemeCellColor];
        footerView.backgroundColor = [UIColor defaultDarkThemeCellColor];
        noMorePagesLabel.textColor = [UIColor twitchLightGrayColor];
        currentPagesLabel.textColor = [UIColor twitchLightLightGrayColor];
    }

    self.view.frame =
        [[RotatableTabBarController instance] landscape] ?
        CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [delegate userListViewWillAppear];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return [users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * cellIdentifier = @"UserSummaryTableViewCell";

    UserSummaryTableViewCell * cell =
        (UserSummaryTableViewCell *)
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        UIColor * cellColor = [[self class] lightCellColor];
        cell =
            [[[UserSummaryTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier
            backgroundColor:cellColor]
            autorelease];
		cell.frame = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
    }

    User * user = [[self sortedUsers] objectAtIndex:indexPath.row];
    [cell setUser:user];

    UIImage * avatarImage = [self getAvatarForUser:user];
    [cell setAvatarImage:avatarImage];

    BOOL landscape = [[RotatableTabBarController instance] landscape];
    [cell setLandscape:landscape];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User * user = [[self sortedUsers] objectAtIndex:indexPath.row];
    [delegate showUserInfoForUser:user];
}

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROW_HEIGHT;
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{   
    NSString * urlAsString = [url absoluteString];
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        [User setAvatar:avatarImage forUrl:urlAsString];

        // avoid calling reloadData by setting the avatars of the visible cells
        NSArray * visibleCells = self.tableView.visibleCells;
        for (UserSummaryTableViewCell * cell in visibleCells)
            if ([cell.avatarImageUrl isEqualToString:urlAsString])
                [cell setAvatarImage:avatarImage];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark UserListTableViewController implementation

- (void)setUsers:(NSArray *)someUsers
{
    self.sortedUserCache = nil;
    
    NSArray * tempUsers = [someUsers copy];
    [users release];
    users = tempUsers;

    NSString * footerFormatString =
        users.count == 1 ?
        NSLocalizedString(@"userlisttableview.footerstring.singular", @"") :
        NSLocalizedString(@"userlisttableview.footerstring.plural", @"");
    currentPagesLabel.text =
        [NSString stringWithFormat:footerFormatString, users.count];
    UIColor * titleColor =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor twitchBlueOnDarkBackgroundColor] : [UIColor twitchBlueColor];
    [loadMoreButton setTitleColor:titleColor forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;
    [loadingMoreIndicator stopAnimating];

    [self.tableView reloadData];
}

- (void)setAllPagesLoaded:(BOOL)allLoaded
{
    loadMoreButton.hidden = allLoaded;
    currentPagesLabel.hidden = allLoaded;
    noMorePagesLabel.hidden = !allLoaded;
}

- (UIImage *)getAvatarForUser:(User *)user
{
    UIImage * avatarImage = [user thumbnailAvatar];
    if (!avatarImage) {
        avatarImage = [[self class] defaultAvatar];
        NSString * url = user.avatar.thumbnailImageUrl;
        if (![alreadySent objectForKey:url]) {
            NSURL * avatarUrl = [NSURL URLWithString:url];
            [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
            [alreadySent setObject:url forKey:url];
        }
    }

    return avatarImage;
}

- (IBAction)loadMoreUsers:(id)sender
{
    NSLog(@"'Load more users' selected");
    [delegate loadMoreUsers];
    [loadMoreButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = NO;
    [loadingMoreIndicator startAnimating];
}

- (NSArray *)sortedUsers
{
    if (!self.sortedUserCache)
        self.sortedUserCache =
            [users sortedArrayUsingSelector:@selector(compare:)];

    return sortedUserCache;
}

+ (UIImage *)defaultAvatar
{
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar48x48.png"] retain];

    return defaultAvatar;
}

+ (UIColor *)lightCellColor
{
    return [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor defaultDarkThemeCellColor] : [UIColor whiteColor];
}

+ (UIColor *)darkCellColor
{
    return [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor defaultDarkThemeCellColor] : [UIColor darkCellBackgroundColor];
}

@end
