//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageConversationViewController.h"
#import "DirectMessage.h"
#import "AsynchronousNetworkFetcher.h"
#import "User+UIAdditions.h"
#import "RotatableTabBarController.h"
#import "NSArray+IterationAdditions.h"
#import "SettingsReader.h"
#import "FastTimelineTableViewCell.h"
#import "TwitbitShared.h"

@interface DirectMessageConversationViewController ()

- (UIImage *)getThumbnailAvatarForUser:(User *)aUser;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;

- (NSInteger)indexForTweetId:(NSNumber *)tweetId;
- (NSInteger)sortedIndexForTweetId:(NSNumber *)tweetId;

- (void)configureCell:(FastTimelineTableViewCell *)cell
    forDirectMessage:(DirectMessage *)dm;

+ (UIImage *)defaultAvatar;

@end

@implementation DirectMessageConversationViewController

static UIImage * defaultAvatar;

@synthesize delegate, sortedTweetCache, segregatedSenderUsername;

- (void)dealloc
{
    [headerView release];
    [headerLine release];
    [footerView release];
    [tweets release];
    [alreadySent release];
    [sortedTweetCache release];
    [segregatedSenderUsername release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    alreadySent = [[NSMutableDictionary dictionary] retain];
    self.tableView.tableFooterView = footerView;
    self.tableView.tableHeaderView = headerView;

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        headerView.backgroundColor = [UIColor twitchDarkGrayColor];
        headerLine.backgroundColor = [UIColor twitchDarkDarkGrayColor];
        footerView.backgroundColor = [UIColor twitchDarkGrayColor];
        self.tableView.backgroundColor = [UIColor twitchDarkGrayColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    static NSString * CellIdentifier =
        @"DirectMessageConversationTableViewCell";

    FastTimelineTableViewCell * cell = (FastTimelineTableViewCell *)
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell =
            [[[FastTimelineTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:CellIdentifier] autorelease];

    DirectMessage * message = [[self sortedTweets] objectAtIndex:indexPath.row];
    [self configureCell:cell forDirectMessage:message];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DirectMessage * message = [[self sortedTweets] objectAtIndex:indexPath.row];
    UIImage * avatar = [message.sender thumbnailAvatar];
    [delegate selectedTweet:message avatarImage:avatar];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DirectMessage * message = [[self sortedTweets] objectAtIndex:indexPath.row];
    NSString * tweetText = message.text;

    BOOL landscape = [[RotatableTabBarController instance] landscape];

    return [FastTimelineTableViewCell
        heightForContent:tweetText
        retweet:NO
        displayType:FastTimelineTableViewCellDisplayTypeNormal
        landscape:landscape];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        NSString * urlAsString = [url absoluteString];
        [User setAvatar:avatarImage forUrl:urlAsString];

        NSArray * visibleCells = self.tableView.visibleCells;
        for (FastTimelineTableViewCell * cell in visibleCells) {
            if ([cell.userData isEqual:urlAsString])
                [cell setAvatar:avatarImage];
        }
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark TimelineViewController implementation

- (void)addTweet:(DirectMessage *)tweet
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

    NSURL * avatarUrl =
        [NSURL URLWithString:tweet.sender.avatar.thumbnailImageUrl];
    [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
}

- (void)deleteTweet:(NSNumber *)tweetId
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

- (void)setMessages:(NSArray *)messages
{
    self.sortedTweetCache = nil;
    NSArray * tempTweets = [messages copy];
    [tweets release];
    tweets = tempTweets;

    [self.tableView reloadData];
}

- (void)selectTweetId:(NSNumber *)tweetId
{
    NSInteger index = [self sortedIndexForTweetId:tweetId];

    // there's a bug in the table view that disallows scrolling to the bottom
    // so, just ignore this if the tweet is near the bottom
    NSInteger tweetCount = [tweets count];
    if (index < tweetCount - 7) {
        NSIndexPath * indexPath =
            [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO
            scrollPosition:UITableViewScrollPositionTop];
    }
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

- (NSInteger)indexForTweetId:(NSNumber *)tweetId
{
    NSInteger index = -1;
    for (int i = 0; i < [tweets count]; i++) {
        DirectMessage * tweet = [tweets objectAtIndex:i];
        if ([tweet.identifier isEqual:tweetId]) {
            index = i;
            break;
        }
    }

    return index;
}   

- (NSInteger)sortedIndexForTweetId:(NSNumber *)tweetId
{
    NSInteger index = -1;
    for (int i = 0; i < [self.sortedTweets count]; i++) {
        DirectMessage * tweet = [self.sortedTweets objectAtIndex:i];
        if ([tweet.identifier isEqual:tweetId]) {
            index = i;
            break;
        }
    }

    return index;
}

- (void)configureCell:(FastTimelineTableViewCell *)cell
    forDirectMessage:(DirectMessage *)dm
{
    [cell setLandscape:[[RotatableTabBarController instance] landscape]];

    FastTimelineTableViewCellDisplayType displayType;
    if ([segregatedSenderUsername isEqual:dm.sender.username])
        displayType = FastTimelineTableViewCellDisplayTypeNormalNoName;
    else
        displayType = FastTimelineTableViewCellDisplayTypeInverted;

    [cell setDisplayType:displayType];
    [cell setAuthor:@""];
    [cell setTimestamp:[dm.created tableViewCellDescription]];
    [cell setTweetText:[dm htmlDecodedText]];
    [cell setAvatar:[self getThumbnailAvatarForUser:dm.sender]];
    cell.userData = dm.sender.avatar.thumbnailImageUrl;
}

+ (UIImage *)defaultAvatar
{
    if (!defaultAvatar)
        defaultAvatar = [UIImage imageNamed:@"DefaultAvatar48x48.png"];

    return defaultAvatar;
}

@end
