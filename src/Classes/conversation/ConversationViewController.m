//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ConversationViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "TweetInfo.h"
#import "TimelineTableViewCell.h"
#import "User+UIAdditions.h"

@interface ConversationViewController ()

@property (nonatomic, retain) UIView * footerView;
@property (nonatomic, retain) UIView * loadingView;
@property (nonatomic, retain) UIView * loadMoreView;
@property (nonatomic, retain) NSMutableArray * conversation;

- (UIImage *)getAvatarForUrl:(NSString *)url;
+ (UIImage *)defaultAvatar;

- (void)displayLoadingView;
- (void)hideLoadingViewAndShowLoadMoreView:(NSNumber *)showLoadMoreView;

- (void)configureFooterForCurrentState;

- (BOOL)canLoadMoreTweets;
- (BOOL)waitingForTweets;

@end

@implementation ConversationViewController

@synthesize delegate, footerView, loadingView, loadMoreView;
@synthesize conversation, batchSize;

- (void)dealloc
{
    self.delegate = nil;

    self.footerView = nil;
    self.loadingView = nil;
    self.loadMoreView = nil;

    self.conversation = nil;
    self.batchSize = nil;

    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
        conversation = [[NSMutableArray alloc] init];

    return self;
}

#pragma mark Public Interface

- (void)loadConversationStartingWithTweets:(NSArray *)tweets
{
    [conversation removeAllObjects];
    [conversation addObjectsFromArray:tweets];

    if (tweets.count < self.batchSize.integerValue + 1) {
        TweetInfo * oldestTweet = [conversation lastObject];
        NSString * tweetId = oldestTweet.inReplyToTwitterTweetId;
        if (tweetId) { // there's still more to load
            [delegate fetchTweetWithId:tweetId];
            waitingFor = [batchSize integerValue];

            //[self displayLoadingView];
            [self configureFooterForCurrentState];
        }
    }

    [self.tableView reloadData];
}

- (void)addTweetsToConversation:(NSArray *)tweets
{
    [conversation addObjectsFromArray:tweets];

    NSMutableArray * indexPaths = [NSMutableArray array];
    NSInteger rowOffset = conversation.count - tweets.count;

    for (NSInteger i = 0; i < tweets.count; ++i) {
        NSIndexPath * indexPath =
            [NSIndexPath indexPathForRow:rowOffset + i inSection:0];
        [indexPaths addObject:indexPath];
    }

    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationTop];

    waitingFor -= tweets.count;
    NSString * nextId = [[conversation lastObject] inReplyToTwitterTweetId];

    if (waitingFor > 0 && nextId)
        [delegate fetchTweetWithId:nextId];
    else {
        waitingFor = 0;
        //NSNumber * canLoadMore = [NSNumber numberWithBool:!!nextId];
        //[self hideLoadingViewAndShowLoadMoreView:canLoadMore];
        //[self performSelector:@selector(hideLoadingViewAndShowLoadMoreView:)
        //           withObject:canLoadMore
        //           afterDelay:0.5];

        [self configureFooterForCurrentState];
    }

    // TODO: stop any animations
}

- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error
{
    NSString * title =
        NSLocalizedString(@"conversationview.load.failed.title", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

    //NSNumber * loadMore =
    //    [NSNumber numberWithBool:
    //    !![[conversation lastObject] inReplyToTwitterTweetId]];
    //[self hideLoadingViewAndShowLoadMoreView:loadMore];

    waitingFor = 0;

    [self configureFooterForCurrentState];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title =
        NSLocalizedString(@"conversationview.title", @"");

    self.loadMoreView.alpha = 0;
    self.loadingView.alpha = 0;

    [self.footerView addSubview:self.loadMoreView];
    [self.footerView addSubview:self.loadingView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    /*
    if ([self waitingForTweets]) {
        // The footer view is always there, and we toggle its alpha from 0 to 1
        // as we hide and show it. We animate hiding it, and removing it from
        // the table view when hiding cuts off the animation.
        self.loadingView.alpha = 1;
        self.tableView.tableFooterView = self.loadingView;
        NSLog(@"Set table view footer to loading view: %@",
            self.tableView.tableFooterView);
    }
    */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];  // Releases the view if it doesn't have a
                                      // superview

    // Release anything that's not essential, such as cached data
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    return conversation.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"ConversationTableViewCell";

    TimelineTableViewCell * cell = (TimelineTableViewCell *)
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[TimelineTableViewCell alloc]
            initWithStyle:UITableViewStylePlain reuseIdentifier:CellIdentifier]
            autorelease];

    TweetInfo * tweet = [conversation objectAtIndex:indexPath.row];

    [cell setName:[tweet displayName]];
    [cell setDate:tweet.timestamp];
    [cell setTweetText:tweet.text];
    [cell setDisplayType:kTimelineTableViewCellTypeNormal];
    [cell setAvatarImage:[self getAvatarForUrl:tweet.user.profileImageUrl]];
    cell.avatarImageUrl = tweet.user.profileImageUrl;

    return cell;
}

#pragma mark UITabeViewDelegate implementation

- (CGFloat)tableView:(UITableView *)tv
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * tweet = [conversation objectAtIndex:indexPath.row];
    TimelineTableViewCellType type = kTimelineTableViewCellTypeNormal;

    return [TimelineTableViewCell heightForContent:tweet.text displayType:type];
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetInfo * info = [conversation objectAtIndex:indexPath.row];
    [self.delegate displayTweetWithId:info.identifier];
}

#pragma mark Button actions

- (IBAction)loadNextBatch:(id)sender
{
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
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark Private implementation

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

- (void)displayLoadingView
{
    self.loadingView.alpha = 1;
    [self.loadMoreView removeFromSuperview];
    [self.footerView addSubview:self.loadingView];
    self.tableView.tableFooterView = self.footerView;
}

- (void)hideLoadingViewAndShowLoadMoreView:(NSNumber *)showLoadMoreView
{
    //NSTimeInterval animationDuration = 2.0; // 0.4;

    self.loadMoreView.alpha = 0;

    [UIView beginAnimations:nil context:NULL];
    /*
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:self.loadMoreView cache:NO];
     */
    //[UIView setAnimationDuration:animationDuration];

    self.loadingView.alpha = 0;

    /*
    if (showLoadMoreView)
        self.tableView.tableFooterView = self.loadMoreView;
    else
        self.tableView.tableFooterView = nil;
    */

    [UIView commitAnimations];

    if (showLoadMoreView.boolValue) {
        [self.footerView addSubview:self.loadMoreView];
        self.tableView.tableFooterView = self.footerView;

        [UIView beginAnimations:nil context:NULL];
        self.loadMoreView.alpha = 1;
        [UIView commitAnimations];
    }

    [self.loadingView removeFromSuperview];
    if (showLoadMoreView.boolValue) {
        [self.footerView addSubview:self.loadMoreView];
        self.tableView.tableFooterView = self.footerView;
    }

    /*
    NSNumber * b = [NSNumber numberWithBool:showLoadMoreView];
    [self performSelector:@selector(loadingAnimationDidFinish:)
               withObject:b
               afterDelay:animationDuration];
     */
}

- (void)loadingAnimationDidFinish:(NSNumber *)showLoadMoreView
{
    if (showLoadMoreView.boolValue)
        self.tableView.tableFooterView = self.loadMoreView;
    else
        self.tableView.tableFooterView = nil;
}

- (void)configureFooterForCurrentState
{
    CGFloat loadMoreAlpha = 0, loadingAlpha = 0;
    UIView * footer = self.tableView.tableFooterView;

    if ([self waitingForTweets]) {
        loadMoreAlpha = 0;
        loadingAlpha = 1;
    } else if ([self canLoadMoreTweets]) {
        loadMoreAlpha = 1;
        loadingAlpha = 0;
    } else {
        loadMoreAlpha = 0;
        loadingAlpha = 0;
    }

    BOOL footerChanged =
        loadMoreAlpha != self.loadMoreView.alpha ||
        loadingAlpha != self.loadingView.alpha;
    if (footerChanged) {
        [UIView beginAnimations:nil context:NULL];

        self.loadMoreView.alpha = loadMoreAlpha;
        self.loadingView.alpha = loadingAlpha;

        [UIView commitAnimations];
    }

    if (loadMoreAlpha != 0 || loadingAlpha != 0)
        footer = self.footerView;
    else
        footer = nil;

    if (footer != self.tableView.tableFooterView)
        if (!self.tableView.tableFooterView)  // no footer - display now
            self.tableView.tableFooterView = footer;
        else if (footer)
            [self performSelector:@selector(setTableViewFooter:)
                   withObject:footer
                   afterDelay:0.5];
        else
            [self performSelector:@selector(setTableViewFooter:)
                       withObject:[NSNull null]
                       afterDelay:0.5];
}

- (void)setTableViewFooter:(id)view
{
    if (!view || [view isEqual:[NSNull null]])
        self.tableView.tableFooterView = nil;
    else
        self.tableView.tableFooterView = view;
}

- (BOOL)canLoadMoreTweets
{
    return !![[conversation lastObject] inReplyToTwitterTweetId];
}

- (BOOL)waitingForTweets
{
    return waitingFor > 0;
}

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar50x50.png"] retain];

    return defaultAvatar;
}

@end
