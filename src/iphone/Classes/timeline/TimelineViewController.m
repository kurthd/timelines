//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineViewController.h"
#import "TimelineTableViewCell.h"
#import "Tweet.h"

@interface Tweet (Sorting)
- (NSComparisonResult)compare:(Tweet *)tweet;
@end

@implementation Tweet (Sorting)
- (NSComparisonResult)compare:(Tweet *)tweet
{
    NSNumber * myId =
        [NSNumber numberWithLongLong:[self.identifier longLongValue]];
    NSNumber * theirId =
        [NSNumber numberWithLongLong:[tweet.identifier longLongValue]];
    return [theirId compare:myId];
}
@end

@interface TimelineViewController ()

- (UIImage *)getAvatarForUrl:(NSString *)url;
- (UIImage *)convertUrlToImage:(NSString *)url;
- (NSArray *)sortedTweets;

@end

@implementation TimelineViewController

@synthesize delegate, sortedTweetCache;

- (void)dealloc
{
    [headerView release];
    [footerView release];
    [fullNameLabel release];
    [usernameLabel release];
    [followingLabel release];

    [tweets release];
    [avatarCache release];

    [currentPagesLabel release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableHeaderView = headerView;
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

    Tweet * tweet = [[self sortedTweets] objectAtIndex:indexPath.row];
    UIImage * avatarImage = [self getAvatarForUrl:tweet.user.profileImageUrl];
    [cell setAvatarImage:avatarImage];
    [cell setName:tweet.user.name];
    [cell setDate:tweet.timestamp];
    [cell setTweetText:tweet.text];

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

    return [TimelineTableViewCell heightForContent:tweetText];
}

#pragma mark TimelineViewController implementation

- (IBAction)loadMoreTweets:(id)sender
{
    NSLog(@"Load more tweets selected");
    [delegate loadMoreTweets];
}

- (void)setUser:(User *)aUser
{
    fullNameLabel.text = aUser.name;
    usernameLabel.text = aUser.username;
    NSString * followingFormatString =
        NSLocalizedString(@"timelineview.userinfo.following", @"");
    followingLabel.text =
        [NSString stringWithFormat:followingFormatString, aUser.friendsCount,
        aUser.followersCount];
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
}

- (UIImage *)getAvatarForUrl:(NSString *)url
{
    UIImage * avatarImage = [avatarCache objectForKey:url];
    if (!avatarImage) {
        avatarImage = [self convertUrlToImage:url];
        [avatarCache setObject:avatarImage forKey:url];
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

    return sortedTweetCache;
}

@end
