//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineViewController.h"
#import "TimelineTableViewCell.h"
#import "Tweet.h"

@interface TimelineViewController ()

- (UIImage *)getAvatarForUrl:(NSString *)url;
- (UIImage *)convertUrlToImage:(NSString *)url;

@end

@implementation TimelineViewController

@synthesize delegate;

- (void)dealloc
{
    [headerView release];
    [fullNameLabel release];
    [usernameLabel release];
    [followingLabel release];
    
    [tweets release];
    [avatarCache release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableHeaderView = headerView;
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

    Tweet * tweet = [tweets objectAtIndex:indexPath.row];
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
    Tweet * tweet = [tweets objectAtIndex:indexPath.row];
    [delegate selectedTweet:tweet];
}

#pragma mark UITableViewDelegate implementation

- (CGFloat)tableView:(UITableView *)aTableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tweet * tweet = [tweets objectAtIndex:indexPath.row];
    NSString * tweetText = tweet.text;

    return [TimelineTableViewCell heightForContent:tweetText];
}

#pragma mark TimelineViewController implementation

- (void)setUser:(User *)aUser
{
    fullNameLabel.text = aUser.name;
    usernameLabel.text = aUser.username;
    NSString * followingFormatString =
        NSLocalizedString(@"timelineview.userinfo.following", @"");
    followingLabel.text =
        [NSString stringWithFormat:followingFormatString, aUser.following,
        aUser.followers];
}

- (void)setTweets:(NSArray *)someTweets
{
    NSArray * tempTweets = [someTweets copy];
    [tweets release];
    tweets = tempTweets;

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

@end
