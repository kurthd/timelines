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

@end

@implementation TimelineViewController

@synthesize delegate, sortedTweetCache, invertedCellUsernames,
    showWithoutAvatars, outgoingSortedTweetCache, incomingSortedTweetCache;

- (void)dealloc
{
    [headerView release];
    [footerView release];
    [avatarView release];
    [fullNameLabel release];
    [usernameLabel release];
    [followingLabel release];
    [inboxOutboxControl release];
    [inboxOutboxView release];

    [tweets release];
    [outgoingTweets release];
    [incomingTweets release];
    [avatarCache release];
    [alreadySent release];
    [user release];

    [sortedTweetCache release];
    [outgoingSortedTweetCache release];
    [incomingSortedTweetCache release];

    [loadMoreButton release];
    [noMorePagesLabel release];
    [currentPagesLabel release];

    [segregatedSenderUsername release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = footerView;
    avatarCache = [[NSMutableDictionary dictionary] retain];
    alreadySent = [[NSMutableDictionary dictionary] retain];
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
    [delegate selectedTweet:tweet
        avatarImage:[avatarCache objectForKey:tweet.user.profileImageUrl]];
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
    NSLog(@"Received avatar for url: %@", url);
    NSString * urlAsString = [url absoluteString];
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        [avatarCache setObject:avatarImage forKey:urlAsString];
        [self.tableView reloadData];

        if ([urlAsString isEqual:user.profileImageUrl])
            avatarView.imageView.image = avatarImage;
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
    UIImage * avatar =
        user ? [avatarCache objectForKey:user.profileImageUrl] : nil;
    [delegate showUserInfoWithAvatar:avatar];
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
    [aUser retain];
    [user release];
    user = aUser;

    if (!aUser) {
        self.tableView.tableHeaderView = nil;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    } else {
        self.tableView.contentInset = UIEdgeInsetsMake(-317, 0, 0, 0);
        self.tableView.tableHeaderView = headerView;
        fullNameLabel.text = aUser.name;
        usernameLabel.text = [NSString stringWithFormat:@"@%@", aUser.username];
        NSString * followingFormatString =
            NSLocalizedString(@"timelineview.userinfo.following", @"");
        followingLabel.text =
            [NSString stringWithFormat:followingFormatString,
            aUser.friendsCount, aUser.followersCount];
        UIImage * avatarImage =
            [self getAvatarForUrl:aUser.profileImageUrl];
        avatarView.imageView.image = avatarImage;
    }
}

- (void)setTweets:(NSArray *)someTweets page:(NSUInteger)page
{
    if (!segregatedSenderUsername) {
        self.sortedTweetCache = nil;
        NSArray * tempTweets = [someTweets copy];
        [tweets release];
        tweets = tempTweets;
    } else {
        TweetInfo * firstTweet =
            [someTweets count] > 0 ? [someTweets objectAtIndex:0] : nil;
        if (firstTweet) {
            if ([firstTweet.user.username isEqual:segregatedSenderUsername]) {
                self.outgoingSortedTweetCache = nil;
                NSArray * tempTweets = [someTweets copy];
                [outgoingTweets release];
                outgoingTweets = tempTweets;
            } else {
                self.incomingSortedTweetCache = nil;
                NSArray * tempTweets = [someTweets copy];
                [incomingTweets release];
                incomingTweets = tempTweets;
            }
        }
    }

    NSString * showingMultPagesFormatString =
        NSLocalizedString(@"timelineview.showingmultiplepages", @"");
    NSString * showingSinglePageFormatString =
        NSLocalizedString(@"timelineview.showingsinglepage", @"");
    currentPagesLabel.text =
        page > 1 ?
        [NSString stringWithFormat:showingMultPagesFormatString, page] :
        showingSinglePageFormatString;

    [self.tableView reloadData];

    [loadMoreButton setTitleColor:[UIColor twitchBlueColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;
}

- (void)clearInboxOutboxTweets
{
    [outgoingTweets release];
    outgoingTweets = [[NSArray array] retain];
    self.outgoingSortedTweetCache = nil;
    [incomingTweets release];
    incomingTweets = [[NSArray array] retain];
    self.incomingSortedTweetCache = nil;
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
        avatarImage = [UIImage imageNamed:@"DefaultAvatar.png"];
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
    NSArray * returnVal;
    if (!segregatedSenderUsername) {
        if (!self.sortedTweetCache)
            self.sortedTweetCache =
                [tweets sortedArrayUsingSelector:@selector(compare:)];
        returnVal = self.sortedTweetCache;
    } else if (showInbox) {
        if (!self.incomingSortedTweetCache)
            self.incomingSortedTweetCache =
                [tweets sortedArrayUsingSelector:@selector(compare:)];
        returnVal = self.incomingSortedTweetCache;
    } else {
        if (!self.outgoingSortedTweetCache)
            self.outgoingSortedTweetCache =
                [tweets sortedArrayUsingSelector:@selector(compare:)];
        returnVal = self.outgoingSortedTweetCache;
    }

    return returnVal;
}

- (void)setSegregateTweetsFromUser:(NSString *)username
{
    NSString * tempUsername = [username copy];
    [segregatedSenderUsername release];
    segregatedSenderUsername = tempUsername;
    
    if (username)
        self.tableView.tableHeaderView = inboxOutboxView;
    else
        self.tableView.tableHeaderView = headerView;
}

- (IBAction)setInboxOutbox:(id)sender
{
    showInbox = inboxOutboxControl.selectedSegmentIndex == 0;
}

@end
