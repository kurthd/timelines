//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageConversationViewController.h"
#import "TimelineTableViewCell.h"
#import "TweetInfo.h"
#import "DirectMessage.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIColor+TwitchColors.h"
#import "DirectMessage+UIAdditions.h"

@interface DirectMessageConversationViewController ()

- (UIImage *)getAvatarForUrl:(NSString *)url;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;
- (void)triggerDelayedRefresh;
- (void)processDelayedRefresh;

+ (UIImage *)defaultAvatar;

@end

@implementation DirectMessageConversationViewController

static UIImage * defaultAvatar;

@synthesize delegate, sortedTweetCache, segregatedSenderUsername;

- (void)dealloc
{
    [footerView release];
    [tweets release];
    [avatarCache release];
    [alreadySent release];
    [sortedTweetCache release];
    [segregatedSenderUsername release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    avatarCache = [[NSMutableDictionary dictionary] retain];
    alreadySent = [[NSMutableDictionary dictionary] retain];
    self.tableView.tableFooterView = footerView;
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
    DirectMessage * message = [[self sortedTweets] objectAtIndex:indexPath.row];

    TimelineTableViewCell * cell = [message cell];

    UIImage * avatarImage =
        [self getAvatarForUrl:message.sender.avatar.thumbnailImageUrl];
    [cell setAvatarImage:avatarImage];

    [cell setName:@""];
    TimelineTableViewCellType displayType;
    if ([segregatedSenderUsername isEqual:message.sender.username])
        displayType = kTimelineTableViewCellTypeNormalNoName;
    else
        displayType = kTimelineTableViewCellTypeInverted;

    [cell setDisplayType:displayType];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DirectMessage * message = [[self sortedTweets] objectAtIndex:indexPath.row];
    UIImage * avatar =
        [avatarCache objectForKey:message.sender.avatar.thumbnailImageUrl];
    [delegate selectedTweet:message avatarImage:avatar];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DirectMessage * message = [[self sortedTweets] objectAtIndex:indexPath.row];
    NSString * tweetText = message.text;

    return [TimelineTableViewCell heightForContent:tweetText
        displayType:kTimelineTableViewCellTypeNormal];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * urlAsString = [url absoluteString];
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        [avatarCache setObject:avatarImage forKey:urlAsString];
        [self triggerDelayedRefresh];
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
    
    [self.tableView reloadData];
}

- (void)setMessages:(NSArray *)messages
{
    self.sortedTweetCache = nil;
    NSArray * tempTweets = [messages copy];
    [tweets release];
    tweets = tempTweets;

    // ensure cells created for all tweets
    for (DirectMessage * message in messages)
        [message cell];

    [self.tableView reloadData];
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
        defaultAvatar = [UIImage imageNamed:@"DefaultAvatar50x50.png"];

    return defaultAvatar;
}

@end
