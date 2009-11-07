//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineViewController.h"
#import "DirectMessage.h"
#import "AsynchronousNetworkFetcher.h"
#import "User+UIAdditions.h"
#import "PhotoBrowserDisplayMgr.h"
#import "RegexKitLite.h"
#import "RotatableTabBarController.h"
#import "NSArray+IterationAdditions.h"
#import "SettingsReader.h"
#import "FastTimelineTableViewCell.h"
#import "TwitbitShared.h"

@interface TimelineViewController ()

@property (nonatomic, retain) NSString * mentionRegex;
@property (nonatomic, retain) NSNumber * visibleTweetId;

- (UIImage *)getLargeAvatarForUser:(User *)aUser;
- (UIImage *)getThumbnailAvatarForUser:(User *)aUser;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;
- (void)triggerDelayedRefresh;
- (void)processDelayedRefresh;

- (NSInteger)indexForTweetId:(NSString *)tweetId;
- (NSInteger)sortedIndexForTweetId:(NSString *)tweetId;

- (void)configureCell:(FastTimelineTableViewCell *)cell
    forTweet:(Tweet *)tweet;

+ (UIImage *)defaultAvatar;
+ (BOOL)displayWithUsername;
+ (BOOL)highlightNewTweets;

@end

@implementation TimelineViewController

static UIImage * defaultAvatar;

static BOOL displayWithUsername;
static BOOL alreadyReadDisplayWithUsernameValue;

static BOOL highlightNewTweets;
static BOOL alreadyReadHighlightNewTweetsValue;

@synthesize delegate, sortedTweetCache, invertedCellUsernames,
    showWithoutAvatars, mentionUsername, mentionRegex, visibleTweetId;

- (void)dealloc
{
    [headerView release];
    [headerBackgroundView release];
    [avatarBackgroundView release];
    [headerTopLine release];
    [headerBottomLine release];
    [headerViewPadding release];
    
    [plainHeaderView release];
    [plainHeaderViewLine release];
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

    [mentionUsername release];

    [visibleTweetId release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // this ensures that any header set before the view is showed scales
    // correctly when changing orientation
    self.view.frame =
        [[RotatableTabBarController instance] landscape] ?
        CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        plainHeaderView.backgroundColor = [UIColor twitchDarkGrayColor];
        plainHeaderViewLine.backgroundColor = [UIColor twitchDarkDarkGrayColor];
        footerView.backgroundColor = [UIColor twitchDarkGrayColor];
        self.tableView.backgroundColor = [UIColor twitchDarkGrayColor];
        currentPagesLabel.textColor = [UIColor twitchLightLightGrayColor];
        noMorePagesLabel.textColor = [UIColor twitchLightGrayColor];

        headerBackgroundView.image =
            [UIImage imageNamed:@"UserHeaderDarkThemeGradient.png"];

        avatarBackgroundView.image =
            [UIImage imageNamed:@"AvatarDarkThemeBackground.png"];

        headerTopLine.backgroundColor = [UIColor blackColor];
        headerBottomLine.backgroundColor = [UIColor blackColor];
        headerViewPadding.backgroundColor = [UIColor defaultDarkThemeCellColor];

        fullNameLabel.textColor = [UIColor whiteColor];
        fullNameLabel.shadowColor = [UIColor blackColor];

        numUpdatesLabel.textColor = [UIColor lightGrayColor];
        numUpdatesLabel.shadowColor = [UIColor blackColor];
    }

    self.tableView.tableFooterView = footerView;
    alreadySent = [[NSMutableDictionary dictionary] retain];
    showInbox = YES;
    self.tableView.tableHeaderView = plainHeaderView;
    self.tableView.contentInset = UIEdgeInsetsMake(-392, 0, 0, 0);
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
    NSLog(@"Timeline view controller will rotate");
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

- (UITableViewCell *)tableView:(UITableView *)tv
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * reuseIdentifier = @"FastTimelineTableViewCell";
    FastTimelineTableViewCell * cell = (FastTimelineTableViewCell *)
        [tv dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell)
        cell =
            [[[FastTimelineTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:reuseIdentifier] autorelease];

    Tweet * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    [self configureCell:cell forTweet:tweet];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tweet * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    [delegate selectedTweet:tweet];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tweet * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    NSString * tweetText = tweet.text;
    FastTimelineTableViewCellDisplayType displayType =
        showWithoutAvatars ?
        FastTimelineTableViewCellDisplayTypeNoAvatar :
        FastTimelineTableViewCellDisplayTypeNormal;
    BOOL landscape = [[RotatableTabBarController instance] landscape];

    return [FastTimelineTableViewCell
        heightForContent:tweetText displayType:displayType landscape:landscape];
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
        for (FastTimelineTableViewCell * cell in visibleCells)
            if ([cell.userData isEqual:urlAsString])
                [cell setAvatar:avatarImage];
        
        NSString * largeProfileUrl = user.avatar.fullImageUrl;
        if ([urlAsString isEqual:largeProfileUrl] && avatarImage)
            [avatarView setImage:avatarImage];
        else if ([urlAsString isEqual:user.avatar.thumbnailImageUrl] &&
            !avatarView.image)
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

- (void)addTweet:(Tweet *)tweet
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

    if (!tweet.user.avatar.thumbnailImage) {
        NSURL * avatarUrl =
            [NSURL URLWithString:tweet.user.avatar.thumbnailImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
    }
}

- (void)deleteTweet:(NSString *)tweetId
{
    NSInteger index = [self indexForTweetId:tweetId];
    NSInteger sortedIndex = [self sortedIndexForTweetId:tweetId];

    NSMutableArray * newTweets = [tweets mutableCopy];
    self.sortedTweetCache = nil;
    [newTweets removeObjectAtIndex:index];

    [tweets release];
    tweets = [[NSArray alloc] initWithArray:newTweets];
    [newTweets release];

    NSIndexPath * indexPath =
        [NSIndexPath indexPathForRow:sortedIndex inSection:0];

    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
        withRowAnimation:UITableViewRowAnimationFade];
}

- (void)setUser:(User *)aUser
{
    NSLog(@"Setting user on timeline view controller");
    [aUser retain];
    [user release];
    user = aUser;

    if (!aUser) {
        self.tableView.tableHeaderView = plainHeaderView;
        self.tableView.contentInset = UIEdgeInsetsMake(-392, 0, 0, 0);
    } else {
        CGRect headerViewFrame = self.view.frame;
        BOOL landscape = [[RotatableTabBarController instance] landscape];
        headerViewFrame.size.width = landscape ? 480 : 320;
        headerViewFrame.size.height = 392;
        headerView.frame = headerViewFrame;

        self.tableView.contentInset = UIEdgeInsetsMake(-317, 0, 0, 0);
        self.tableView.tableHeaderView = headerView;

        fullNameLabel.text =
            user.name && user.name.length > 0 &&
            ![[self class] displayWithUsername] ?
            user.name : user.username;
        NSNumberFormatter * formatter =
            [[[NSNumberFormatter alloc] init] autorelease];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        numUpdatesLabel.text =
            [NSString stringWithFormat:
            NSLocalizedString(@"userinfoview.statusescount.formatstring", @""),
            [formatter stringFromNumber:user.statusesCount]];
        UIImage * avatarImage = [self getLargeAvatarForUser:aUser];
        [avatarView setImage:avatarImage];
    }
}

- (void)setTweets:(NSArray *)someTweets page:(NSUInteger)page
    visibleTweetId:(NSNumber *)aVisibleTweetId
{
    NSLog(@"Setting %d tweets on timeline; page: %d", [someTweets count], page);
    if (aVisibleTweetId && !self.visibleTweetId)
        self.visibleTweetId = aVisibleTweetId;
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

    [self.tableView reloadData];

    UIColor * buttonColor =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor twitchBlueOnDarkBackgroundColor] : [UIColor twitchBlueColor];
        
    [loadMoreButton setTitleColor:buttonColor forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;

    if (aVisibleTweetId) {
        NSLog(@"Scrolling to visible tweet id %@", aVisibleTweetId);
        NSUInteger visibleRow = 0;
        for (Tweet * tweet in self.sortedTweets) {
            if ([aVisibleTweetId isEqual:tweet.identifier])
                break;
            visibleRow++;
        }

        if (visibleRow < [self.sortedTweets count]) {
            NSLog(@"Scrolling to row %d", visibleRow);
            NSIndexPath * scrollIndexPath =
                [NSIndexPath indexPathForRow:visibleRow inSection:0];
            if ([someTweets count] > 8) {
                // 'if' statement is a hack
                // for some reason, if the cells don't fill the whole table view
                // the following call results in a large blank header
                [self.tableView scrollToRowAtIndexPath:scrollIndexPath
                    atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            [self.tableView flashScrollIndicators];
        }
    }
}

- (void)selectTweetId:(NSString *)tweetId
{
    NSInteger index = [self sortedIndexForTweetId:tweetId];

    // there's a bug in the table view that disallows scrolling to the bottom
    // so, just ignore this if the tweet is near the bottom
    NSInteger tweetCount = [tweets count];
    if (index < tweetCount - 5) {
        NSIndexPath * indexPath =
            [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO
            scrollPosition:UITableViewScrollPositionTop];
    }
}

- (void)setAllPagesLoaded:(BOOL)allLoaded
{
    loadMoreButton.hidden = allLoaded;
    currentPagesLabel.hidden = allLoaded;
    noMorePagesLabel.hidden = !allLoaded;
}

- (UIImage *)getLargeAvatarForUser:(User *)aUser
{
    UIImage * avatarImage = [aUser fullAvatar];
    if (!avatarImage) {
        avatarImage = [[self class] defaultAvatar];
        NSString * url = aUser.avatar.fullImageUrl;
        if (![alreadySent objectForKey:url]) {
            NSURL * avatarUrl = [NSURL URLWithString:url];
            [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
            [alreadySent setObject:url forKey:url];
        }
    }
    
    return avatarImage;
}

- (UIImage *)getThumbnailAvatarForUser:(User *)aUser
{
    UIImage * avatarImage = [aUser thumbnailAvatar];
    if (!avatarImage) {
        avatarImage = [[self class] defaultAvatar];
        NSString * url = aUser.avatar.thumbnailImageUrl;
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
            [[tweets sortedArrayUsingSelector:@selector(compare:)]
            arrayByReversingContents];

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
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar48x48.png"] retain];

    return defaultAvatar;
}

- (IBAction)showFullProfileImage:(id)sender
{
    NSLog(@"Profile image selected");

    NSString * url = user.avatar.fullImageUrl;
    UIImage * avatarImage = [UIImage imageWithData:user.avatar.fullImage];

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:avatarImage url:url name:user.name];
    [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
}

- (NSNumber *)mostRecentTweetId
{
    NSNumber * mostRecentId;
    if ([[self sortedTweetCache] count] > 0) {
        Tweet * mostRecentTweet = [[self sortedTweetCache] objectAtIndex:0];
        mostRecentId = mostRecentTweet.identifier;
    } else
        mostRecentId = nil;

    return mostRecentId;
}

// HACK: Exposed to allow for "Save Search" button
- (void)setTimelineHeaderView:(UIView *)aView
{
    // this ensures that any header set before the view is showed scales
    // correctly when changing orientation
    self.view.frame =
        [[RotatableTabBarController instance] landscape] ?
        CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);

    self.tableView.tableHeaderView = aView;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)setMentionUsername:(NSString *)aMentionUsername
{
    NSString * tempUsername = [aMentionUsername copy];
    [mentionUsername release];
    mentionUsername = tempUsername;

    self.mentionRegex =
        [NSString stringWithFormat:@"\\B@%@", mentionUsername];
}

- (NSInteger)indexForTweetId:(NSString *)tweetId
{
    NSInteger index = -1;
    for (int i = 0; i < [tweets count]; i++) {
        Tweet * tweet = [tweets objectAtIndex:i];
        if ([tweet.identifier isEqual:tweetId]) {
            index = i;
            break;
        }
    }

    return index;
}   

- (NSInteger)sortedIndexForTweetId:(NSString *)tweetId
{
    NSInteger index = -1;
    for (int i = 0; i < [self.sortedTweets count]; i++) {
        Tweet * tweet = [self.sortedTweets objectAtIndex:i];
        if ([tweet.identifier isEqual:tweetId]) {
            index = i;
            break;
        }
    }

    return index;
}

- (void)configureCell:(FastTimelineTableViewCell *)cell
    forTweet:(Tweet *)tweet
{
    [cell setLandscape:[[RotatableTabBarController instance] landscape]];

    FastTimelineTableViewCellDisplayType displayType;
    if (showWithoutAvatars)
        displayType = FastTimelineTableViewCellDisplayTypeNoAvatar;
    else if ([invertedCellUsernames containsObject:tweet.user.username])
        displayType = FastTimelineTableViewCellDisplayTypeInverted;
    else
        displayType = FastTimelineTableViewCellDisplayTypeNormal;
    [cell setDisplayType:displayType];

    [cell setTweetText:[tweet.text stringByDecodingHtmlEntities]];
    [cell setAuthor:tweet.user.username];
    [cell setTimestamp:[tweet.timestamp tableViewCellDescription]];
    [cell setFavorite:[tweet.favorited boolValue]];

    [cell setAvatar:[self getThumbnailAvatarForUser:tweet.user]];
    [cell setUserData:tweet.user.avatar.thumbnailImageUrl];

    BOOL newerThanVisibleTweetId =
        self.visibleTweetId &&
        [tweet.identifier compare:self.visibleTweetId] !=
        NSOrderedDescending;
    BOOL darkenForOld =
        [[self class] highlightNewTweets] && newerThanVisibleTweetId;
    [cell displayAsOld:darkenForOld];

    BOOL highlightForMention =
    self.mentionRegex ?
        [tweet.text isMatchedByRegex:self.mentionRegex] : NO;
    [cell displayAsMention:highlightForMention];
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

+ (BOOL)highlightNewTweets
{
    if (!highlightNewTweets) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        highlightNewTweets = [defaults boolForKey:@"highlight_new"];
        alreadyReadHighlightNewTweetsValue = YES;
    }

    return highlightNewTweets;
}

@end
