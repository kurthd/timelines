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

@property (nonatomic, retain) NSString * mentionString;
@property (nonatomic, retain) NSNumber * visibleTweetId;
@property (nonatomic, assign) BOOL flashingScrollIndicators;
@property (nonatomic, copy) NSArray * filteredTweets;

- (UIImage *)getLargeAvatarForUser:(User *)aUser;
- (UIImage *)getThumbnailAvatarForUser:(User *)aUser;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;
- (void)triggerDelayedRefresh;
- (void)processDelayedRefresh;

- (Tweet *)tweetAtIndex:(NSIndexPath *)indexPath inTableView:(UITableView *)tv;

- (NSInteger)indexForTweetId:(NSString *)tweetId;
- (NSInteger)sortedIndexForTweetId:(NSString *)tweetId;

- (void)configureCell:(FastTimelineTableViewCell *)cell forTweet:(Tweet *)tweet;

- (void)setScrollIndicatorBlackoutTimer;

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
    showWithoutAvatars, mentionUsername, mentionString, visibleTweetId,
    flashingScrollIndicators, filteredTweets, searchBar;

- (void)dealloc
{
    [headerView release];
    [headerBackgroundView release];
    [headerTopLine release];
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
    [filteredTweets release];

    [loadMoreButton release];
    [noMorePagesLabel release];
    [currentPagesLabel release];
    [loadingMoreIndicator release];

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

        headerTopLine.backgroundColor = [UIColor blackColor];
        headerViewPadding.backgroundColor = [UIColor defaultDarkThemeCellColor];

        fullNameLabel.textColor = [UIColor whiteColor];
        fullNameLabel.shadowColor = [UIColor blackColor];

        numUpdatesLabel.textColor = [UIColor lightGrayColor];
        numUpdatesLabel.shadowColor = [UIColor blackColor];

        searchBar.tintColor = [UIColor twitchDarkDarkGrayColor];
    }

    self.tableView.tableFooterView = footerView;
    alreadySent = [[NSMutableDictionary dictionary] retain];
    showInbox = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BOOL landscape = [[RotatableTabBarController instance] landscape];
    self.view.frame =
        landscape ? CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);

    UITableView * searchTableView =
        self.searchDisplayController.searchResultsTableView;

    if (lastShownLandscapeValue != landscape) {
        [self.tableView reloadData];
        [searchTableView reloadData];
    }

    [self setScrollIndicatorBlackoutTimer];

    [searchTableView
        deselectRowAtIndexPath:searchTableView.indexPathForSelectedRow
        animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    lastShownLandscapeValue = [[RotatableTabBarController instance] landscape];
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
    [self.searchDisplayController.searchResultsTableView reloadData];
}

#pragma mark UISearchDisplayControllerDelegate implementation

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
    shouldReloadTableForSearchString:(NSString *)searchString
{
    // Not sure why, but this needs to be set every time results are shown
    UITableView * searchTableView =
        self.searchDisplayController.searchResultsTableView;
    searchTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if ([SettingsReader displayTheme] == kDisplayThemeDark)
        searchTableView.backgroundColor = [UIColor twitchDarkDarkGrayColor];
    else
        searchTableView.backgroundColor = [UIColor twitchLightLightGrayColor];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:
        @"SELF.text contains[cd] %@ OR SELF.user.username contains[cd] %@ OR SELF.user.name contains[cd] %@",
        searchString, searchString, searchString];
    self.filteredTweets =
        [[self sortedTweets] filteredArrayUsingPredicate:predicate];

    return YES;
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tv
    numberOfRowsInSection:(NSInteger)section
{
    return tv == self.tableView ?
        [[self sortedTweets] count] : [self.filteredTweets count];
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

    Tweet * tweet = [self tweetAtIndex:indexPath inTableView:tv];
    [self configureCell:cell forTweet:tweet];

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tweet * tweet = [self tweetAtIndex:indexPath inTableView:tv];
    [delegate selectedTweet:tweet];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tweet * tweet = [self tweetAtIndex:indexPath inTableView:aTableView];
    Tweet * displayTweet = tweet.retweet ? tweet.retweet : tweet;
    NSString * tweetText = displayTweet.text;
    FastTimelineTableViewCellDisplayType displayType =
        showWithoutAvatars ?
        FastTimelineTableViewCellDisplayTypeNoAvatar :
        FastTimelineTableViewCellDisplayTypeNormal;
    BOOL landscape = [[RotatableTabBarController instance] landscape];

    return [FastTimelineTableViewCell
        heightForContent:tweetText retweet:!!tweet.retweet
        displayType:displayType landscape:landscape];
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
    [loadingMoreIndicator startAnimating];
    loadMoreButton.enabled = NO;
}

- (void)addTweet:(Tweet *)tweet
{
    // HACK
    NSIndexPath * selectedIndexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];

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
        self.tableView.contentInset = UIEdgeInsetsMake(-392, 0, -300, 0);
    } else {
        CGRect headerViewFrame = self.view.frame;
        BOOL landscape = [[RotatableTabBarController instance] landscape];
        headerViewFrame.size.width = landscape ? 480 : 320;
        headerViewFrame.size.height = 392;
        headerView.frame = headerViewFrame;

        self.tableView.contentInset = UIEdgeInsetsMake(-317, 0, -300, 0);
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

    BOOL firstDisplay = !tweets;

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
    [loadingMoreIndicator stopAnimating];

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
            if (!flashingScrollIndicators)
                [self.tableView flashScrollIndicators];
        }
    } else if (firstDisplay && [tweets count] > 0) {
        NSIndexPath * scrollIndexPath =
            [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:scrollIndexPath
            atScrollPosition:UITableViewScrollPositionTop animated:NO];
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

            // Fetching after delay to allow scrolling to continue. Calling this
            // here is as much superstition as anything. I have no idea if this
            // actually helps scrolling performance.
            [self performSelector:@selector(fetchUrl:)
                       withObject:avatarUrl
                       afterDelay:0.1];
            [alreadySent setObject:url forKey:url];
        }
    }

    return avatarImage;
}

- (void)fetchUrl:(NSURL *)url
{
    [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];
}

- (UIImage *)convertUrlToImage:(NSString *)url
{
    NSURL * avatarUrl = [NSURL URLWithString:url];
    NSData * avatarData = [NSData dataWithContentsOfURL:avatarUrl];

    return [UIImage imageWithData:avatarData];
}

- (Tweet *)tweetAtIndex:(NSIndexPath *)indexPath inTableView:(UITableView *)tv
{
    NSArray * array =
        tv == self.tableView ? [self sortedTweets] : self.filteredTweets;
    return [array objectAtIndex:indexPath.row];
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

    if ([SettingsReader displayTheme] == kDisplayThemeLight)
        self.tableView.backgroundColor = [UIColor whiteColor];

    self.tableView.tableHeaderView = aView;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, -300, 0);
}

- (void)setMentionUsername:(NSString *)aMentionUsername
{
    NSString * tempUsername = [aMentionUsername copy];
    [mentionUsername release];
    mentionUsername = tempUsername;

    self.mentionString =
        mentionUsername ?
        [NSString stringWithFormat:@"@%@", mentionUsername] :
        nil;
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

- (void)configureCell:(FastTimelineTableViewCell *)cell forTweet:(Tweet *)tweet
{
    Tweet * displayTweet;
    NSString * retweetAuthor = nil;
    if (tweet.retweet) {
        displayTweet = tweet.retweet;
        retweetAuthor = tweet.user.username;
    } else
        displayTweet = tweet;

    [cell setLandscape:[[RotatableTabBarController instance] landscape]];

    FastTimelineTableViewCellDisplayType displayType;
    if (showWithoutAvatars)
        displayType = FastTimelineTableViewCellDisplayTypeNoAvatar;
    else if ([invertedCellUsernames containsObject:displayTweet.user.username])
        displayType = FastTimelineTableViewCellDisplayTypeInverted;
    else
        displayType = FastTimelineTableViewCellDisplayTypeNormal;
    [cell setDisplayType:displayType];

    [cell setTweetText:[displayTweet htmlDecodedText]];
    [cell setAuthor:[displayTweet displayName]];
    [cell setTimestamp:[displayTweet.timestamp tableViewCellDescription]];
    [cell setFavorite:[displayTweet.favorited boolValue]];
    [cell setGeocoded:!!displayTweet.location];

    [cell setAvatar:[self getThumbnailAvatarForUser:displayTweet.user]];
    [cell setUserData:displayTweet.user.avatar.thumbnailImageUrl];

    [cell setRetweetAuthor:retweetAuthor];

    BOOL newerThanVisibleTweetId =
        self.visibleTweetId &&
        [tweet.identifier compare:self.visibleTweetId] !=
        NSOrderedDescending;
    BOOL darkenForOld =
        [[self class] highlightNewTweets] && newerThanVisibleTweetId;
    [cell displayAsOld:darkenForOld];

    BOOL highlightForMention = NO;
    if (self.mentionString) {
        NSRange where = [displayTweet.text rangeOfString:mentionString
                                          options:NSCaseInsensitiveSearch];
        highlightForMention = !NSEqualRanges(where, NSMakeRange(NSNotFound, 0));
    }
    [cell displayAsMention:highlightForMention];
}

- (void)setScrollIndicatorBlackoutTimer
{
    flashingScrollIndicators = YES;
    [self performSelector:@selector(setFlashingScrollIndicators:) withObject:nil
        afterDelay:1.0];
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
