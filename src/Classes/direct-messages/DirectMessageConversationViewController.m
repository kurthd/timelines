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
#import "User+UIAdditions.h"

@interface DirectMessageConversationViewController ()

- (UIImage *)getThumbnailAvatarForUser:(User *)aUser;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;

- (NSInteger)indexForTweetId:(NSString *)tweetId;
- (NSInteger)sortedIndexForTweetId:(NSString *)tweetId;

+ (UIImage *)defaultAvatar;

@end

@implementation DirectMessageConversationViewController

static UIImage * defaultAvatar;

@synthesize delegate, sortedTweetCache, segregatedSenderUsername;

- (void)dealloc
{
    [headerView release];
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

    UIImage * defaultAvatar = [[self class] defaultAvatar];
    if (![cell avatarImage] || [cell avatarImage] == defaultAvatar)
        [cell setAvatarImage:[self getThumbnailAvatarForUser:message.sender]];

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
    UIImage * avatar = [message.sender thumbnailAvatar];
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
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        NSString * urlAsString = [url absoluteString];
        [User setAvatar:avatarImage forUrl:urlAsString];

        NSArray * visibleCells = self.tableView.visibleCells;
        for (TimelineTableViewCell * cell in visibleCells) {
            NSLog(@"cell.avatarImageUrl: %@", cell.avatarImageUrl);
            NSLog(@"urlAsString: %@", urlAsString);
            if ([cell.avatarImageUrl isEqualToString:urlAsString])
                [cell setAvatarImage:avatarImage];
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
    
    [self.tableView reloadData];
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
            [tweets sortedArrayUsingSelector:@selector(compare:)];

    return self.sortedTweetCache;
}

- (NSInteger)indexForTweetId:(NSString *)tweetId
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

- (NSInteger)sortedIndexForTweetId:(NSString *)tweetId
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

+ (UIImage *)defaultAvatar
{
    if (!defaultAvatar)
        defaultAvatar = [UIImage imageNamed:@"DefaultAvatar50x50.png"];

    return defaultAvatar;
}

@end
