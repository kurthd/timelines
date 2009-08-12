//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TweetViewController.h"
#import "TweetTextTableViewCell.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "RegexKitLite.h"

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
@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, retain) UIWebView * tweetContentView;

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

- (void)configureCell:(UITableViewCell *)cell asFavorite:(BOOL)favorite;

+ (UIImage *)defaultAvatar;

@end

@implementation TweetViewController

@synthesize delegate, navigationController, tweetContentView, tweet, avatar;
@synthesize showsExtendedActions;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;

    [headerView release];
    [fullNameLabel release];
    [usernameLabel release];

    [tweetTextTableViewCell release];
    self.tweetContentView = nil;

    self.tweet = nil;
    self.avatar = nil;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [delegate showingTweetDetails];
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
    BOOL tweetTextRow =
        indexPath.section == kTweetDetailsSection &&
        indexPath.row == kTweetTextRow;

    return tweetTextRow ? tweetContentView.frame.size.height : 44;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;
    NSString * identifier = [self reuseIdentifierForRowAtIndexPath:indexPath];

    BOOL tweetTextRow =
        indexPath.section == kTweetDetailsSection &&
        indexPath.row == kTweetTextRow;

    if (!tweetTextRow) {
        cell = [tv dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil)
            cell = [self createCellForRowAtIndexPath:indexPath
                                     reuseIdentifier:identifier];
    }

    if (indexPath.section == kTweetDetailsSection) {
        if (indexPath.row == kTweetTextRow) {
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
    } else if (indexPath.section == kComposeActionsSection) {
        NSString * text = nil;
        UIImage * image = nil;
        UIImage * highlightedImage = nil;

        if (indexPath.row == kPublicReplyRow) {
            text =
                NSLocalizedString(@"tweetdetailsview.publicreply.label", @"");
            image = [UIImage imageNamed:@"PublicReplyButtonIcon.png"];
            highlightedImage =
                [UIImage imageNamed:@"PublicReplyButtonIconHighlighted.png"];
        } else if (indexPath.row == kDirectMessageRow) {
            text =
                NSLocalizedString(@"tweetdetailsview.directmessage.label", @"");
            image = [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
            highlightedImage = [UIImage imageNamed:@"Envelope.png"];
        } else if (indexPath.row == kRetweetRow) {
            text = NSLocalizedString(@"tweetdetailsview.retweet.label", @"");
            image = [UIImage imageNamed:@"RetweetButtonIcon.png"];
            highlightedImage =
                [UIImage imageNamed:@"RetweetButtonIconHighlighted.png"];
        }

        cell.textLabel.text = text;
        cell.imageView.image = image;
        cell.imageView.highlightedImage = highlightedImage;
    } else if (indexPath.section == kTweetActionsSection)
        if (indexPath.row == kFavoriteRow) {
            BOOL favorite = [tweet.favorited boolValue];
            [self configureCell:cell asFavorite:favorite];
        }

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kTweetDetailsSection) {
        if (indexPath.row == kConversationRow) {
            NSString * tweetId =
                [tweet.inReplyToTwitterTweetId description];
            NSString * replyToUsername = tweet.inReplyToTwitterUsername;
            [delegate loadNewTweetWithId:tweetId username:replyToUsername];
        }
    } else if (indexPath.section == kComposeActionsSection) {
        if (indexPath.row == kPublicReplyRow)
            [self sendReply];
        else if (indexPath.row == kDirectMessageRow)
            [self sendDirectMessage];
        else if (indexPath.row == kRetweetRow)
            [self retweet];
    } else if (indexPath.section == kTweetActionsSection)
        if (indexPath.row == kFavoriteRow)
            [self toggleFavoriteValue];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
            NSLog(@"Showing tweets for user: %@", username);
            [delegate showTweetsForUser:username];
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
            [delegate showPhotoInBrowser:remotePhoto];
        } else
            [delegate visitWebpage:webpage];
    }

    return navigationType != UIWebViewNavigationTypeLinkClicked;
}

#pragma mark Public interface implementation

- (void)displayTweet:(TweetInfo *)aTweet avatar:(UIImage *)anAvatar
    onNavigationController:(UINavigationController *)navController
{
    self.tweet = aTweet;
    self.avatar = anAvatar;
    self.navigationController = navController;

    [self loadTweetWebView];
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
           webAddress =
                [NSString stringWithFormat:@"http://twitter.com/%@/status/%@",
                self.tweet.user, self.tweet.identifier];
            NSLog(@"Opening tweet in browser (%@)...", webAddress);
            [delegate visitWebpage:webAddress];
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

    NSString * webAddress =
         [NSString stringWithFormat:@"http://twitter.com/%@/status/%@",
         self.tweet.user, self.tweet.identifier];
    NSString * body =
        [NSString stringWithFormat:@"%@\n\n%@", self.tweet.text,
        webAddress];
    [picker setMessageBody:body isHTML:NO];

    [self presentModalViewController:picker animated:YES];

    [picker release];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    self.avatar = [UIImage imageWithData:data];
    [avatarImage setImage:self.avatar];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark Tweet actions

- (IBAction)showUserTweets:(id)sender
{
    UIImage * actualAvatar =
        self.avatar != [[self class] defaultAvatar] ? self.avatar : nil;
    [delegate showUserInfoForUser:tweet.user withAvatar:actualAvatar];
}

- (IBAction)showFullProfileImage:(id)sender
{
    User * selectedUser = tweet.user;

    NSString * url =
        [selectedUser.profileImageUrl
        stringByReplacingOccurrencesOfString:@"_normal."
        withString:@"."];
    UIImage * remoteAvatar =
        [url isEqualToString:selectedUser.profileImageUrl] ?
        (avatarImage.image != [[self class] defaultAvatar] ?
        avatarImage.image : nil) : nil;

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:remoteAvatar url:url name:selectedUser.name];
    [delegate showPhotoInBrowser:remotePhoto];
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
    BOOL favorite = [tweet.favorited boolValue];
    favorite = !favorite;
    [delegate setFavorite:favorite];
    tweet.favorited = [NSNumber numberWithBool:favorite];

    NSArray * visibleCells = self.tableView.visibleCells;
    for (UITableViewCell * cell in visibleCells) {
        NSString * favoriteString =
            !favorite ?  // the value before we toggled it
            NSLocalizedString(@"tweetdetailsview.unfavorite.label", @"") :
            NSLocalizedString(@"tweetdetailsview.favorite.label", @"");

        if ([cell.textLabel.text isEqualToString:favoriteString])
            [self configureCell:cell asFavorite:favorite];
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
        usernameLabel.text = tweet.user.username;
        fullNameLabel.text = tweet.user.name;
    } else {
        usernameLabel.text = @"";
        fullNameLabel.text = tweet.user.username;
    }

    if (!self.avatar) {
        [self fetchRemoteImage:tweet.user.profileImageUrl];
        self.avatar = [[self class] defaultAvatar];
    }
    [avatarImage setImage:self.avatar];

    [self.tableView reloadData];
    self.tableView.contentInset = UIEdgeInsetsMake(-300, 0, 0, 0);
}

- (void)fetchRemoteImage:(NSString *)avatarUrlString
{
    NSURL * url = [NSURL URLWithString:avatarUrlString];
    [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];
}

- (void)configureCell:(UITableViewCell *)cell asFavorite:(BOOL)favorite
{
    if (favorite) {
        cell.textLabel.text =
            NSLocalizedString(@"tweetdetailsview.unfavorite.label", @"");
        cell.imageView.image = [UIImage imageNamed:@"Favorite.png"];
    } else {
        cell.textLabel.text =
            NSLocalizedString(@"tweetdetailsview.favorite.label", @"");
        cell.imageView.image = [UIImage imageNamed:@"NotFavorite.png"];
    }
}

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;

    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar.png"] retain];

    return defaultAvatar;
}

@end
