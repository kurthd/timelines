//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineViewController.h"
#import "TimelineTableViewCell.h"
#import "TweetInfo.h"
#import "DirectMessage.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIColor+TwitchColors.h"
#import "TweetInfo+UIAdditions.h"
#import "User+UIAdditions.h"
#import "PhotoBrowserDisplayMgr.h"

@interface TimelineViewController ()

- (UIImage *)getAvatarForUrl:(NSString *)url;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;
- (void)triggerDelayedRefresh;
- (void)processDelayedRefresh;

+ (UIImage *)defaultAvatar;
+ (BOOL)displayWithUsername;

@end

@implementation TimelineViewController

static UIImage * defaultAvatar;
static BOOL displayWithUsername;
static BOOL alreadyReadDisplayWithUsernameValue;

@synthesize delegate, sortedTweetCache, invertedCellUsernames,
    showWithoutAvatars;

- (void)dealloc
{
    [headerView release];
    [footerView release];
    [avatarView release];
    [fullNameLabel release];
    [numUpdatesLabel release];

    [tweets release];
    [alreadySent release];
    [user release];

    [sortedTweetCache release];

    [loadMoreButton release];
    [noMorePagesLabel release];
    [currentPagesLabel release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = footerView;
    alreadySent = [[NSMutableDictionary dictionary] retain];
    showInbox = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    return [[self sortedTweets] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];

    TimelineTableViewCell * cell = [tweet cell];

    UIImage * avatarImage = [self getAvatarForUrl:tweet.user.profileImageUrl];
    [cell setAvatarImage:avatarImage];

    TimelineTableViewCellType displayType;
    if (showWithoutAvatars)
        displayType = kTimelineTableViewCellTypeNoAvatar;
    else if ([invertedCellUsernames containsObject:tweet.user.username])
        displayType = kTimelineTableViewCellTypeInverted;
    else
        displayType = kTimelineTableViewCellTypeNormal;

    [cell setDisplayType:displayType];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    [delegate selectedTweet:tweet];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    NSString * tweetText = tweet.text;
    TimelineTableViewCellType displayType =
        showWithoutAvatars ?
        kTimelineTableViewCellTypeNoAvatar :
        kTimelineTableViewCellTypeNormal;

    return [TimelineTableViewCell heightForContent:tweetText
        displayType:displayType];
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
        for (TimelineTableViewCell * cell in visibleCells)
            if ([cell.avatarImageUrl isEqualToString:urlAsString])
                [cell setAvatarImage:avatarImage];

        NSString * largeProfileUrl =
            [User largeAvatarUrlForUrl:user.profileImageUrl];
        if ([urlAsString isEqual:largeProfileUrl])
            [avatarView setImage:avatarImage];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark TimelineViewController implementation

- (IBAction)loadMoreTweets:(id)sender
{
    NSLog(@"'Load more tweets' selected");
    [delegate loadMoreTweets];
    [loadMoreButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = NO;
}

- (IBAction)showUserInfo:(id)sender
{
    NSLog(@"'Show user info' selected");
    [delegate showUserInfo];
}

- (void)addTweet:(TweetInfo *)tweet
{
    NSMutableArray * newTweets = [tweets mutableCopy];
    self.sortedTweetCache = nil;
    [newTweets insertObject:tweet atIndex:0];

    [tweets release];
    tweets = [[NSArray alloc] initWithArray:newTweets];
    [newTweets release];

    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
        withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView scrollToRowAtIndexPath:
        [NSIndexPath indexPathForRow:0 inSection:0]
        atScrollPosition:UITableViewScrollPositionNone animated:YES];

    if (![self getAvatarForUrl:tweet.user.profileImageUrl]) {
        NSURL * avatarUrl = [NSURL URLWithString:tweet.user.profileImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
    }
}

- (void)setUser:(User *)aUser
{
    [aUser retain];
    [user release];
    user = aUser;

    if (!aUser) {
        self.tableView.tableHeaderView = nil;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    } else {
        self.tableView.contentInset = UIEdgeInsetsMake(-317, 0, 0, 0);
        self.tableView.tableHeaderView = headerView;
        fullNameLabel.text =
            user.name && user.name.length > 0 &&
            ![[self class] displayWithUsername] ?
            user.name : user.username;
         numUpdatesLabel.text =
            [NSString stringWithFormat:
            NSLocalizedString(@"userinfoview.statusescount.formatstring", @""),
            user.statusesCount];
        NSString * largeProfileUrl =
            [User largeAvatarUrlForUrl:aUser.profileImageUrl];
        UIImage * avatarImage = [self getAvatarForUrl:largeProfileUrl];
        [avatarView setImage:avatarImage];
    }
}

- (void)setTweets:(NSArray *)someTweets page:(NSUInteger)page
    visibleTweetId:(NSString *)visibleTweetId
{
    NSLog(@"Displaying tweets without inbox/outbox...");
    self.sortedTweetCache = nil;
    NSArray * tempTweets = [someTweets copy];
    [tweets release];
    tweets = tempTweets;

    NSString * showingMultPagesFormatString =
        NSLocalizedString(@"timelineview.showingmultiplepages", @"");
    NSString * showingSinglePageFormatString =
        NSLocalizedString(@"timelineview.showingsinglepage", @"");
    currentPagesLabel.text =
        page > 1 ?
        [NSString stringWithFormat:showingMultPagesFormatString, page] :
        showingSinglePageFormatString;

    // ensure cells created for all tweets
    for (TweetInfo * tweet in someTweets)
        [tweet cell];

    [self.tableView reloadData];

    [loadMoreButton setTitleColor:[UIColor twitchBlueColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;
    
    if (visibleTweetId) {
        NSLog(@"Scrolling to visible tweet id %@", visibleTweetId);
        NSUInteger visibleRow = 0;
        for (TweetInfo * tweetInfo in self.sortedTweets) {
            if ([visibleTweetId isEqual:tweetInfo.identifier])
                break;
            visibleRow++;
        }
        if (visibleRow < [self.sortedTweets count]) {
            NSLog(@"Scrolling to row %d", visibleRow);
            NSIndexPath * scrollIndexPath =
                [NSIndexPath indexPathForRow:visibleRow inSection:0];
            [self.tableView scrollToRowAtIndexPath:scrollIndexPath
                atScrollPosition:UITableViewScrollPositionTop animated:NO];
            [self.tableView flashScrollIndicators];
        }
    }
}

- (void)setAllPagesLoaded:(BOOL)allLoaded
{
    loadMoreButton.hidden = allLoaded;
    currentPagesLabel.hidden = allLoaded;
    noMorePagesLabel.hidden = !allLoaded;
}

- (UIImage *)getAvatarForUrl:(NSString *)url
{
    UIImage * avatarImage = [User avatarForUrl:url];
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

- (UIImage *)convertUrlToImage:(NSString *)url
{
    NSURL * avatarUrl = [NSURL URLWithString:url];
    NSData * avatarData = [NSData dataWithContentsOfURL:avatarUrl];

    return [UIImage imageWithData:avatarData];
}

- (NSArray *)sortedTweets
{
    if (!self.sortedTweetCache)
        self.sortedTweetCache =
            [tweets sortedArrayUsingSelector:@selector(compare:)];

    return self.sortedTweetCache;
}

- (void)triggerDelayedRefresh
{
    if (!delayedRefreshTriggered)
        [self performSelector:@selector(processDelayedRefresh) withObject:nil
            afterDelay:0.5];

    delayedRefreshTriggered = YES;
}

- (void)processDelayedRefresh
{
    [self.tableView reloadData];
    delayedRefreshTriggered = NO;
}

+ (UIImage *)defaultAvatar
{
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar50x50.png"] retain];

    return defaultAvatar;
}

- (IBAction)showFullProfileImage:(id)sender
{
    NSLog(@"Profile image selected");

    NSString * url =
        [user.profileImageUrl
        stringByReplacingOccurrencesOfString:@"_normal."
        withString:@"."];
    UIImage * avatarImage =
        [url isEqualToString:user.profileImageUrl] ?
        (avatarView.image != [[self class] defaultAvatar] ?
        avatarView.image : nil) :
        nil;

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:avatarImage url:url name:user.name];
    [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
}

- (NSString *)mostRecentTweetId
{
    NSString * mostRecentId;
    if ([[self sortedTweetCache] count] > 0) {
        TweetInfo * mostRecentTweet =
            (TweetInfo *)[[self sortedTweetCache] objectAtIndex:0];
        mostRecentId = mostRecentTweet.identifier;
    } else
        mostRecentId = nil;

    return mostRecentId;
}

// HACK: Exposed to allow for "Save Search" button
- (void)setTimelineHeaderView:(UIView *)aView
{
    self.tableView.tableHeaderView = aView;
}

+ (BOOL)displayWithUsername
{
    if (!alreadyReadDisplayWithUsernameValue) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSInteger displayNameValAsNumber =
            [defaults integerForKey:@"display_name"];
        displayWithUsername = displayNameValAsNumber;
    }

    alreadyReadDisplayWithUsernameValue = YES;

    return displayWithUsername;
}

@end
