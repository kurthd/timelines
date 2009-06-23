//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineViewController.h"
#import "TimelineTableViewCell.h"
#import "TweetInfo.h"
#import "DirectMessage.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIColor+TwitchColors.h"

@interface TimelineViewController ()

- (UIImage *)getAvatarForUrl:(NSString *)url;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;
- (void)fetchAvatarsForTweets;

@end

@implementation TimelineViewController

@synthesize delegate, sortedTweetCache, invertedCellUsernames;

- (void)dealloc
{
    [headerView release];
    [footerView release];
    [fullNameLabel release];
    [usernameLabel release];
    [followingLabel release];

    [tweets release];
    [avatarCache release];

    [loadMoreButton release];
    [noMorePagesLabel release];
    [currentPagesLabel release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = footerView;
    avatarCache = [[NSMutableDictionary dictionary] retain];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return [tweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"TimelineTableViewCell";

    TimelineTableViewCell * cell =
        (TimelineTableViewCell *)
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray * nib =
            [[NSBundle mainBundle] loadNibNamed:@"TimelineTableViewCell"
            owner:self options:nil];

        cell = [nib objectAtIndex:0];
    }

    TweetInfo * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    UIImage * avatarImage = [self getAvatarForUrl:tweet.user.profileImageUrl];
    [cell setAvatarImage:avatarImage];
    [cell setName:tweet.user.name];
    [cell setDate:tweet.timestamp];
    [cell setTweetText:tweet.text];
    [cell setInvert:[invertedCellUsernames containsObject:tweet.user.username]];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    [delegate selectedTweet:tweet
        avatarImage:[avatarCache objectForKey:tweet.user.profileImageUrl]];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    NSString * tweetText = tweet.text;

    return [TimelineTableViewCell heightForContent:tweetText];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    [avatarCache setObject:[UIImage imageWithData:data]
        forKey:[url absoluteString]];
    [self.tableView reloadData];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark TimelineViewController implementation

- (IBAction)loadMoreTweets:(id)sender
{
    NSLog(@"Load more tweets selected");
    [delegate loadMoreTweets];
    [loadMoreButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = NO;
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
        atScrollPosition:UITableViewScrollPositionTop animated:YES];

    NSURL * avatarUrl = [NSURL URLWithString:tweet.user.profileImageUrl];
    [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
}

- (void)setUser:(User *)aUser
{
    if (!aUser) {
        self.tableView.tableHeaderView = nil;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    } else {
        self.tableView.contentInset = UIEdgeInsetsMake(-317, 0, 0, 0);
        self.tableView.tableHeaderView = headerView;
        fullNameLabel.text = aUser.name;
        usernameLabel.text = aUser.username;
        NSString * followingFormatString =
            NSLocalizedString(@"timelineview.userinfo.following", @"");
        followingLabel.text =
            [NSString stringWithFormat:followingFormatString,
            aUser.friendsCount, aUser.followersCount];
    }
}

- (void)setTweets:(NSArray *)someTweets page:(NSUInteger)page
{
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

    [self fetchAvatarsForTweets];

    [loadMoreButton setTitleColor:[UIColor twitchBlueColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;
}

- (void)fetchAvatarsForTweets
{
    NSMutableDictionary * alreadySent = [NSMutableDictionary dictionary];
    for (TweetInfo * tweetInfo in tweets) {
        NSString * avatarUrlAsString = tweetInfo.user.profileImageUrl;
        if (![avatarCache objectForKey:avatarUrlAsString] &&
            ![alreadySent objectForKey:avatarUrlAsString]) {

            NSLog(@"Getting avatar for url %@", avatarUrlAsString);
            NSURL * avatarUrl =
                [NSURL URLWithString:avatarUrlAsString];
            [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
            [alreadySent setObject:avatarUrlAsString forKey:avatarUrlAsString];
        }
    }
}

- (UIImage *)getAvatarForUrl:(NSString *)url
{
    UIImage * avatarImage = [avatarCache objectForKey:url];
    if (!avatarImage)
        avatarImage = [UIImage imageNamed:@"DefaultAvatar.png"];

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

    return sortedTweetCache;
}

@end
