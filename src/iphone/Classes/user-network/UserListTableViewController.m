//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserListTableViewController.h"
#import "UserSummaryTableViewCell.h"
#import "User.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIColor+TwitchColors.h"

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

    return [theirId compare:myId];
}
@end

@interface UserListTableViewController ()

- (UIImage *)getAvatarForUrl:(NSString *)url;
- (NSArray *)sortedUsers;

+ (UIImage *)defaultAvatar;

@end

@implementation UserListTableViewController

static UIImage * defaultAvatar;

@synthesize delegate, sortedUserCache;

- (void)dealloc
{
    [footerView release];
    [currentPagesLabel release];
    [loadMoreButton release];
    [noMorePagesLabel release];

    [users release];
    [avatarCache release];
    [alreadySent release];

    [sortedUserCache release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.tableFooterView = footerView;

    avatarCache = [[NSMutableDictionary dictionary] retain];
    alreadySent = [[NSMutableDictionary dictionary] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [delegate userListViewWillAppear];
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
    static NSString * cellIdentifier = @"UserSummaryTableViewCell";

    UserSummaryTableViewCell * cell =
        (UserSummaryTableViewCell *)
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray * nib =
            [[NSBundle mainBundle] loadNibNamed:@"UserSummaryTableViewCell"
            owner:self options:nil];

        cell = [nib objectAtIndex:0];
    }

    User * user = [[self sortedUsers] objectAtIndex:indexPath.row];
    [cell setAvatar:[self getAvatarForUrl:user.profileImageUrl]];
    [cell setName:user.name];
    NSString * username = [NSString stringWithFormat:@"@%@", user.username];
    [cell setUsername:username];
    NSString * followingFormatString =
        NSLocalizedString(@"userlisttableview.following", @"");
    NSString * followingText =
        [NSString stringWithFormat:followingFormatString, user.friendsCount,
        user.followersCount];
    [cell setFollowingText:followingText];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User * user = [[self sortedUsers] objectAtIndex:indexPath.row];
    [delegate showTweetsForUser:user.username];
}

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * urlAsString = [url absoluteString];
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        [avatarCache setObject:avatarImage forKey:urlAsString];
        [self.tableView reloadData];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark UserListTableViewController implementation

- (void)setUsers:(NSArray *)someUsers page:(NSUInteger)page
{
    self.sortedUserCache = nil;
    
    NSArray * tempUsers = [someUsers copy];
    [users release];
    users = tempUsers;

    NSString * showingMultPagesFormatString =
        NSLocalizedString(@"timelineview.showingmultiplepages", @"");
    NSString * showingSinglePageFormatString =
        NSLocalizedString(@"timelineview.showingsinglepage", @"");
    currentPagesLabel.text =
        page > 1 ?
        [NSString stringWithFormat:showingMultPagesFormatString, page] :
        showingSinglePageFormatString;

    [loadMoreButton setTitleColor:[UIColor twitchBlueColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;
    
    [self.tableView reloadData];
}

- (void)setAllPagesLoaded:(BOOL)allLoaded
{
    loadMoreButton.hidden = allLoaded;
    currentPagesLabel.hidden = allLoaded;
    noMorePagesLabel.hidden = !allLoaded;
}

- (UIImage *)getAvatarForUrl:(NSString *)url
{
    UIImage * avatarImage = [avatarCache objectForKey:url];
    if (!avatarImage) {
        avatarImage = [[self class] defaultAvatar];
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
        defaultAvatar = [UIImage imageNamed:@"DefaultAvatar.png"];

    return defaultAvatar;
}

@end
