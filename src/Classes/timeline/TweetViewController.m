//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TweetViewController.h"
#import "TweetTextTableViewCell.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "RegexKitLite.h"
#import "User+UIAdditions.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "PhotoBrowserDisplayMgr.h"

static NSString * usernameRegex = @"\\B(@[\\w_]+)";

static const NSInteger NUM_SECTIONS = 3;
enum Sections {
    kTweetDetailsSection,
    kComposeActionsSection,
    kTweetActionsSection
};

static const NSInteger NUM_TWEET_DETAILS_ROWS = 2;
enum TweetDetailsRows {
    kTweetTextRow,
    kConversationRow
};

static const NSInteger NUM_COMPOSE_ACTION_ROWS = 3;
enum ComposeActionRows {
    kPublicReplyRow,
    kDirectMessageRow,
    kRetweetRow
};

static const NSInteger NUM_TWEET_ACTION_ROWS = 1;
enum TweetActionRows {
    kFavoriteRow
};

@interface TweetViewController ()

@property (nonatomic, retain) UINavigationController * navigationController;

@property (nonatomic, retain) TweetInfo * tweet;
@property (nonatomic, retain) UIWebView * tweetContentView;
@property (readonly) MarkAsFavoriteCell * favoriteCell;

- (NSString *)reuseIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)createCellForRowAtIndexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(NSString *)reuseIdentifier;

- (void)displayTweet;
- (void)loadTweetWebView;

- (void)retweet;
- (void)sendReply;
- (void)sendDirectMessage;
- (void)toggleFavoriteValue;

- (void)displayComposerMailSheet;

- (void)fetchRemoteImage:(NSString *)avatarUrlString;

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath;

+ (UIImage *)defaultAvatar;

@end

@implementation TweetViewController

@synthesize delegate, navigationController, tweetContentView, tweet;
@synthesize showsExtendedActions;
@synthesize realParentViewController;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;

    [headerView release];
    [fullNameLabel release];
    [usernameLabel release];
    [favoriteCell release];

    [tweetTextTableViewCell release];
    self.tweetContentView = nil;

    self.tweet = nil;

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    tweetTextTableViewCell =
        [[TweetTextTableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:@"TweetTextTableViewCell"];

    self.tableView.tableHeaderView = headerView;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 300, 0, 0);

    if (self.navigationItem && self.navigationItem.title.length == 0)
        self.navigationItem.title =
            NSLocalizedString(@"tweetdetailsview.title", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [delegate showingTweetDetails:self];
    [self.tableView flashScrollIndicators];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return showsFavoriteButton ? NUM_SECTIONS : NUM_SECTIONS - 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger nrows = 0;
    switch (section) {
        case kTweetDetailsSection:
            nrows = tweet.inReplyToTwitterTweetId ?
                NUM_TWEET_DETAILS_ROWS : NUM_TWEET_DETAILS_ROWS - 1;
            break;
        case kComposeActionsSection:
            nrows = showsExtendedActions ? NUM_COMPOSE_ACTION_ROWS : 1;
            break;
        case kTweetActionsSection:
            nrows = NUM_TWEET_ACTION_ROWS;
            break;
    }

    return nrows;
}

- (CGFloat)tableView:(UITableView *)tv
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = 44;
    
    if (indexPath.section == kTweetDetailsSection &&
        indexPath.row == kTweetTextRow)
        rowHeight = tweetContentView.frame.size.height;
    
    return rowHeight;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;

    NSIndexPath * transformedPath = [self indexForActualIndexPath:indexPath];

    BOOL tweetTextRow =
        transformedPath.section == kTweetDetailsSection &&
        transformedPath.row == kTweetTextRow;

    if (!tweetTextRow) {
        NSString * identifier =
            [self reuseIdentifierForRowAtIndexPath:indexPath];
        cell = [tv dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil)
            cell = [self createCellForRowAtIndexPath:indexPath
                                     reuseIdentifier:identifier];
    }

    if (transformedPath.section == kTweetDetailsSection) {
        if (transformedPath.row == kTweetTextRow) {
            [tweetTextTableViewCell.contentView addSubview:tweetContentView];
            cell = tweetTextTableViewCell;
        } else if (indexPath.row == kConversationRow) {
            NSString * formatString =
                NSLocalizedString(@"tweetdetailsview.inreplyto.formatstring",
                @"");
            cell.textLabel.text =
                [NSString stringWithFormat:formatString,
                tweet.inReplyToTwitterUsername];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (transformedPath.section == kComposeActionsSection) {
        NSString * text = nil;
        UIImage * image = nil;
        UIImage * highlightedImage = nil;

        if (transformedPath.row == kPublicReplyRow) {
            text =
                NSLocalizedString(@"tweetdetailsview.publicreply.label", @"");
            image = [UIImage imageNamed:@"PublicReplyButtonIcon.png"];
            highlightedImage =
                [UIImage imageNamed:@"PublicReplyButtonIconHighlighted.png"];
        } else if (transformedPath.row == kDirectMessageRow) {
            text =
                NSLocalizedString(@"tweetdetailsview.directmessage.label", @"");
            image = [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
            highlightedImage =
                [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
        } else if (transformedPath.row == kRetweetRow) {
            text = NSLocalizedString(@"tweetdetailsview.retweet.label", @"");
            image = [UIImage imageNamed:@"RetweetButtonIcon.png"];
            highlightedImage =
                [UIImage imageNamed:@"RetweetButtonIconHighlighted.png"];
        }

        cell.textLabel.text = text;
        cell.imageView.image = image;
        cell.imageView.highlightedImage = highlightedImage;
    } else if (transformedPath.section == kTweetActionsSection)
        if (transformedPath.row == kFavoriteRow) {
            cell = self.favoriteCell;
            [self.favoriteCell setMarkedState:[tweet.favorited boolValue]];
            [self.favoriteCell setUpdatingState:markingFavorite];
        }

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * transformedPath = [self indexForActualIndexPath:indexPath];

    if (transformedPath.section == kTweetDetailsSection) {
        if (transformedPath.row == kConversationRow)
            [delegate loadConversationFromTweetId:tweet.identifier];
    } else if (transformedPath.section == kComposeActionsSection) {
        if (transformedPath.row == kPublicReplyRow)
            [self sendReply];
        else if (transformedPath.row == kDirectMessageRow)
            [self sendDirectMessage];
        else if (transformedPath.row == kRetweetRow)
            [self retweet];
    } else if (transformedPath.section == kTweetActionsSection)
        if (transformedPath.row == kFavoriteRow)
            [self toggleFavoriteValue];

    [self.tableView deselectRowAtIndexPath:transformedPath animated:YES];
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView *)view
{
    CGSize size = [tweetContentView sizeThatFits:CGSizeZero];

    CGRect frame = tweetContentView.frame;
    frame.size.width = size.width;
    frame.size.height = size.height;
    tweetContentView.frame = frame;

    // remove from UIWindow's key window
    [tweetContentView removeFromSuperview];
    [tweetTextTableViewCell.contentView addSubview:tweetContentView];

    if (navigationController)
        [navigationController pushViewController:self animated:YES];

    [self displayTweet];
}

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(UIWebViewNavigationType)navigationType
{
    NSString * inReplyToString;
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSString * webpage = [[request URL] absoluteString];

        RKLRegexOptions options = RKLCaseless;
        NSRange range = NSMakeRange(0, webpage.length);
        NSError * error = 0;

        static NSString * imageUrlRegex =
            @"^http://twitpic.com/.+|"
             "^http://.*\\.?yfrog.com/.+|"
             "^http://tinypic.com/.+|"
             "^http://twitgoo.com/.+|"
             "^http://mobypicture.com/.+|"
             "\\.jpg$|\\.jpeg$|\\.bmp|\\.gif|\\.png";
        if ([webpage isMatchedByRegex:usernameRegex]) {
            NSString * username =
                [[webpage stringByMatching:usernameRegex] substringFromIndex:1];
            NSLog(@"Showing user info for user: %@", username);
            [delegate showUserInfoForUsername:username];
        } else if ([webpage isMatchedByRegex:@"/\\B(#[\\w_]+)"]) {
            NSString * query =
                [[webpage stringByMatching:@"/\\B(#[\\w_]+)"]
                substringFromIndex:1];
            NSLog(@"Showing search results for '%@'", query);
            [delegate showResultsForSearch:query];
        } else if (inReplyToString = [webpage stringByMatching:@"#\\d*"]) {
            NSString * tweetId = [inReplyToString substringFromIndex:1];
            NSString * replyToUsername = self.tweet.inReplyToTwitterUsername;
            [delegate loadNewTweetWithId:tweetId username:replyToUsername];
        } else if ([webpage isMatchedByRegex:@"^mailto:"]) {
            NSLog(@"Opening 'Mail' with url: %@", webpage);
            NSURL * url = [[NSURL alloc] initWithString:webpage];
            [[UIApplication sharedApplication] openURL:url];
        } else if ([webpage isMatchedByRegex:imageUrlRegex options:options
            inRange:range error:&error]) {
            // load twitpic url in photo browser
            RemotePhoto * remotePhoto =
                [[RemotePhoto alloc]
                initWithImage:nil url:webpage name:webpage];
            [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
        } else
            [[TwitchWebBrowserDisplayMgr instance] visitWebpage:webpage];
    }

    return navigationType != UIWebViewNavigationTypeLinkClicked;
}

#pragma mark Public interface implementation

- (void)displayTweet:(TweetInfo *)aTweet
    onNavigationController:(UINavigationController *)navController
{
    self.tweet = aTweet;
    self.navigationController = navController;

    [self loadTweetWebView];
}

- (void)setFavorited:(BOOL)favorited
{
    [self.favoriteCell setMarkedState:favorited];
    [self.favoriteCell setUpdatingState:NO];
    markingFavorite = NO;
}

- (void)setUsersTweet:(BOOL)usersTweet
{
    // ignore for now
}

- (void)hideFavoriteButton:(BOOL)hide
{
    showsFavoriteButton = !hide;
} 

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)sheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"User clicked button at index: %d.", buttonIndex);

    NSString * webAddress;
    NSString * title =
        NSLocalizedString(@"photobrowser.unabletosendmail.title", @"");
    NSString * message =
        NSLocalizedString(@"photobrowser.unabletosendmail.message", @"");

    switch (buttonIndex) {
        case 0:
           webAddress = [tweet tweetUrl];
            NSLog(@"Opening tweet in browser (%@)...", webAddress);
            [[TwitchWebBrowserDisplayMgr instance] visitWebpage:webAddress];
            break;
        case 1:
            NSLog(@"Sending tweet in email...");
            if ([MFMailComposeViewController canSendMail]) {
                [self displayComposerMailSheet];
            } else {     
                UIAlertView * alert =
                    [UIAlertView simpleAlertViewWithTitle:title
                    message:message];
                [alert show];
            }
            break;
    }

    [sheet autorelease];
}

#pragma mark MFMailComposeViewControllerDelegate implementation

- (void)mailComposeController:(MFMailComposeViewController *)controller
    didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    if (result == MFMailComposeResultFailed) {
        NSString * title =
            NSLocalizedString(@"photobrowser.emailerror.title", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title
            message:[error description]];
        [alert show];
    }

    [controller dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
}

#pragma mark Emailing tweets

- (void)displayComposerMailSheet
{
    MFMailComposeViewController * picker =
        [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    static NSString * subjectRegex = @"\\S+\\s\\S+\\s\\S+\\s\\S+\\s\\S+";
    NSString * subject =
        [self.tweet.text stringByMatching:subjectRegex];
    if (subject && ![subject isEqual:@""])
        subject = [NSString stringWithFormat:@"%@...", subject];
    else
        subject = self.tweet.text;
    [picker setSubject:subject];

    NSString * body =
        [NSString stringWithFormat:@"%@\n\n%@", self.tweet.text,
        [tweet tweetUrl]];
    [picker setMessageBody:body isHTML:NO];

    [self.realParentViewController presentModalViewController:picker
        animated:YES];

    [picker release];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    UIImage * avatar = [UIImage imageWithData:data];
    NSString * urlAsString = [url absoluteString];
    [User setAvatar:avatar forUrl:urlAsString];
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);
    if (NSEqualRanges([urlAsString rangeOfString:@"_normal."], notFoundRange) &&
        avatar)
        [avatarImage setImage:avatar];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark Tweet actions

- (IBAction)showUserTweets:(id)sender
{
    [delegate showUserInfoForUser:tweet.user];
}

- (IBAction)showFullProfileImage:(id)sender
{
    User * selectedUser = tweet.user;

    NSString * url = selectedUser.avatar.fullImageUrl;
    UIImage * remoteAvatar =
        [UIImage imageWithData:selectedUser.avatar.fullImage];

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:remoteAvatar url:url name:selectedUser.name];
    [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
}

- (void)retweet
{
    [delegate reTweetSelected];
}

- (void)sendReply
{
    [delegate replyToTweet];
}

- (void)sendDirectMessage
{
    [delegate sendDirectMessageToUser:tweet.user.username];
}

- (void)toggleFavoriteValue
{
    if (!markingFavorite) {
        markingFavorite = YES;
        [self.favoriteCell setUpdatingState:YES];
        [delegate setFavorite:![tweet.favorited boolValue]];
    }
}

#pragma mark Private implementation

- (NSString *)reuseIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier = nil;

    switch (indexPath.section) {
        case kTweetDetailsSection:
            switch (indexPath.row) {
                case kTweetTextRow:
                    identifier = @"TweetTextTableViewCell";
                    break;
                case kConversationRow:
                    identifier = @"TweetConversationTableViewCell";
                    break;
            }
            break;
        case kComposeActionsSection:
            identifier = @"ComposeActionsTableViewCell";
            break;
        case kTweetActionsSection:
            identifier = @"TweetActionsSection";
            break;
    }

    return identifier;
}

- (UITableViewCell *)createCellForRowAtIndexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(NSString *)reuseIdentifier
{
    UITableViewCell * cell = nil;

    BOOL tweetTextRow =
        indexPath.section == kTweetDetailsSection &&
        indexPath.row == kTweetTextRow;
    if (tweetTextRow)
        cell = tweetTextTableViewCell;
    else
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:reuseIdentifier] autorelease];

    return cell;
}

- (void)loadTweetWebView
{
    CGRect frame = CGRectMake(5, 0, 290, 20);
    UIWebView * contentView = [[UIWebView alloc] initWithFrame:frame];
    contentView.delegate = self;
    contentView.backgroundColor = [UIColor clearColor];
    contentView.opaque = NO;
    contentView.dataDetectorTypes = UIDataDetectorTypeAll;

    [self.tweetContentView removeFromSuperview];
    self.tweetContentView = contentView;
    [contentView release];

    // The view must be added as the subview of a visible view, otherwise the
    // height will not be calculated when -sizeToFit: is called in the
    // -webViewDidFinishLoad delegate method. Adding it here seems to have
    // no effect on the display at all, but the view does calculate its frame
    // correctly. Is there a better way to do this?
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:tweetContentView];

    NSString * html = [self.tweet textAsHtml];
    [tweetContentView loadHTMLStringRelativeToMainBundle:html];
}

- (void)displayTweet
{
    if (tweet.user.name.length > 0) {
        usernameLabel.text =
            [NSString stringWithFormat:@"@%@", tweet.user.username];
        fullNameLabel.text = tweet.user.name;
    } else {
        usernameLabel.text = @"";
        fullNameLabel.text = tweet.user.username;
    }

    NSString * largeAvatarUrl =
        [User largeAvatarUrlForUrl:tweet.user.avatar.thumbnailImageUrl];

    UIImage * avatar = [User avatarForUrl:largeAvatarUrl];
    if (!avatar)
        avatar = [User avatarForUrl:tweet.user.avatar.thumbnailImageUrl];
    if (!avatar)
        avatar = [[self class] defaultAvatar];

    [avatarImage setImage:avatar];

    [self fetchRemoteImage:largeAvatarUrl];
    [self fetchRemoteImage:tweet.user.avatar.thumbnailImageUrl];

    [self.tableView reloadData];
    self.tableView.contentInset = UIEdgeInsetsMake(-300, 0, 0, 0);
}

- (void)fetchRemoteImage:(NSString *)avatarUrlString
{
    NSURL * url = [NSURL URLWithString:avatarUrlString];
    [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];
}

- (UIViewController *)realParentViewController
{
    return self.parentViewController ?
        self.parentViewController : realParentViewController;
}

- (MarkAsFavoriteCell *)favoriteCell
{
    if (!favoriteCell) {
        NSArray * nib =
            [[[NSBundle mainBundle] loadNibNamed:@"MarkAsFavoriteCell"
            owner:self options:nil] retain];

         favoriteCell = [nib objectAtIndex:0];
    }

    return favoriteCell;
}

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row =
        indexPath.section == kComposeActionsSection &&
        indexPath.row == kPublicReplyRow && !showsExtendedActions ?
        kDirectMessageRow : indexPath.row;
    NSInteger section = indexPath.section;

    return [NSIndexPath indexPathForRow:row inSection:section];
}

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;

    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar.png"] retain];

    return defaultAvatar;
}

@end
