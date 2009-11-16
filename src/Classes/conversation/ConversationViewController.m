//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ConversationViewController.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "Tweet+GeneralHelpers.h"
#import "User+UIAdditions.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"
#import "FastTimelineTableViewCell.h"
#import "TwitbitShared.h"

@interface ConversationViewController ()

@property (nonatomic, retain) UIView * footerView;
@property (nonatomic, retain) UIView * loadingView;
@property (nonatomic, retain) UIView * loadMoreView;
@property (nonatomic, retain) NSMutableArray * conversation;

- (UIImage *)getThumbnailAvatarForUser:(User *)user;
+ (UIImage *)defaultAvatar;

- (void)configureFooterForCurrentState;

- (BOOL)canLoadMoreTweets;
- (BOOL)waitingForTweets;

- (void)loadConversationFromTweetId:(NSNumber *)tweetId;

@end

@implementation ConversationViewController

@synthesize delegate, footerView, loadingView, loadMoreView;
@synthesize conversation, batchSize;

- (void)dealloc
{
    self.delegate = nil;

    [headerView release];
    [headerViewLine release];
    self.footerView = nil;
    [plainFooterView release];
    self.loadingView = nil;
    [loadMoreButton release];
    [loadingLabel release];
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

#pragma mark Public Interface

- (void)loadConversationStartingWithTweets:(NSArray *)tweets
{
    [conversation removeAllObjects];
    [conversation addObjectsFromArray:tweets];

    if (tweets.count < self.batchSize.integerValue + 1) {
        Tweet * oldestTweet = [conversation lastObject];
        NSNumber * tweetId = oldestTweet.inReplyToTwitterTweetId;
        if (tweetId) {  // there's still more to load
            [self loadConversationFromTweetId:tweetId];
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
    NSNumber * nextId = [[conversation lastObject] inReplyToTwitterTweetId];
    
    if (waitingFor > 0 && nextId)
        [delegate fetchTweetWithId:nextId];
    else {
        waitingFor = 0;
        [self configureFooterForCurrentState];
    }
}

- (void)failedToFetchTweetWithId:(NSNumber *)tweetId error:(NSError *)error
{
    NSString * title =
        NSLocalizedString(@"conversationview.load.failed.title", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

    waitingFor = 0;
    [self configureFooterForCurrentState];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.view.backgroundColor = [UIColor twitchDarkGrayColor];
        headerView.backgroundColor = [UIColor twitchDarkGrayColor];
        plainFooterView.backgroundColor = [UIColor twitchDarkGrayColor];
        headerViewLine.backgroundColor = [UIColor twitchDarkDarkGrayColor];
        loadingView.backgroundColor = [UIColor twitchDarkGrayColor];
        loadingLabel.textColor = [UIColor lightGrayColor];
        footerView.backgroundColor = [UIColor twitchDarkGrayColor];
        loadMoreView.backgroundColor = [UIColor twitchDarkGrayColor];

        NSString * backgroundImageName =
            @"SaveSearchDarkThemeButtonBackground.png";
        UIImage * background =
            [[UIImage imageNamed:backgroundImageName]
            stretchableImageWithLeftCapWidth:10 topCapHeight:0];
        NSString * highlightedBackgroundImageName =
            @"SaveSearchDarkThemeButtonBackgroundHighlighted.png";
        UIImage * selectedBackground =
            [[UIImage imageNamed:highlightedBackgroundImageName]
            stretchableImageWithLeftCapWidth:10 topCapHeight:0];
        [loadMoreButton setBackgroundImage:background
            forState:UIControlStateNormal];
        [loadMoreButton setBackgroundImage:selectedBackground
            forState:UIControlStateHighlighted];
        [loadMoreButton setTitleColor:[UIColor twitchBlueOnDarkBackgroundColor]
            forState:UIControlStateNormal];
        [loadMoreButton setTitleColor:[UIColor grayColor]
            forState:UIControlStateDisabled];
    }

    self.navigationItem.title =
        NSLocalizedString(@"conversationview.title", @"");

    self.loadMoreView.alpha = 0;
    self.loadingView.alpha = 0;

    self.tableView.tableHeaderView = headerView;
    
    [self.footerView addSubview:self.loadMoreView];
    [self.footerView addSubview:self.loadingView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self configureFooterForCurrentState];
    [self.tableView reloadData];
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

    FastTimelineTableViewCell * cell = (FastTimelineTableViewCell *)
        [tv dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell =
            [[[FastTimelineTableViewCell alloc]
            initWithStyle:UITableViewStylePlain reuseIdentifier:CellIdentifier]
            autorelease];

    Tweet * tweet = [conversation objectAtIndex:indexPath.row];

    [cell setAuthor:[tweet displayName]];
    [cell setTimestamp:[tweet.timestamp tableViewCellDescription]];
    [cell setTweetText:[tweet htmlDecodedText]];

    BOOL landscape = [[RotatableTabBarController instance] landscape];
    [cell setLandscape:landscape];

    if ([delegate isCurrentUser:tweet.user.username])
        [cell setDisplayType:FastTimelineTableViewCellDisplayTypeInverted];
    else
        [cell setDisplayType:FastTimelineTableViewCellDisplayTypeNormal];

    [cell setAvatar:[self getThumbnailAvatarForUser:tweet.user]];
    cell.userData = tweet.user.avatar.thumbnailImageUrl;

    return cell;
}

#pragma mark UITabeViewDelegate implementation

- (CGFloat)tableView:(UITableView *)tv
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tweet * tweet = [conversation objectAtIndex:indexPath.row];
    FastTimelineTableViewCellDisplayType type =
        FastTimelineTableViewCellDisplayTypeNormal;

    BOOL landscape = [[RotatableTabBarController instance] landscape];

    return [FastTimelineTableViewCell
        heightForContent:tweet.text displayType:type landscape:landscape];
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tweet * info = [conversation objectAtIndex:indexPath.row];
    [self.delegate displayTweetWithId:info.identifier];
}

#pragma mark Button actions

- (IBAction)loadNextBatch:(id)sender
{
    Tweet * tweet = [conversation lastObject];
    if (tweet.inReplyToTwitterTweetId) {
        [self loadConversationFromTweetId:tweet.inReplyToTwitterTweetId];
        [self configureFooterForCurrentState];
    }
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
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark Private implementation

- (UIImage *)getThumbnailAvatarForUser:(User *)user
{
    UIImage * avatarImage = [user thumbnailAvatar];
    if (!avatarImage) {
        avatarImage = [[self class] defaultAvatar];
        NSString * url = user.avatar.thumbnailImageUrl;
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

- (void)configureFooterForCurrentState
{
    //
    // The general strategy here is to see what the view should look like
    // based on the current state, and update the table footer view as
    // appropriate. It only updates the view if something has changed.
    //

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
    
    UIEdgeInsets edgeInsets;
    if (loadMoreAlpha != 0 || loadingAlpha != 0)
        footer = self.footerView;
    else {
        footer = plainFooterView;
        edgeInsets.bottom = -700;
    }
    edgeInsets.top = -392;
    edgeInsets.left = 0;
    self.tableView.contentInset = edgeInsets;
    
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

- (void)loadConversationFromTweetId:(NSNumber *)tweetId
{
    [delegate fetchTweetWithId:tweetId];
    waitingFor = [batchSize integerValue];
}

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar48x48.png"] retain];

    return defaultAvatar;
}

@end
