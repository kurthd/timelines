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
    kTweetActionsSection,
    kTweetDeleteSection
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

static const NSInteger NUM_TWEET_DELETE_ROWS = 1;
enum TweetDeleteRows {
    kDeleteRow
};

enum TweetActionSheets {
    kTweetActionSheetActions,
    kTweetActionSheetDeleteConfirmation
};

@interface TweetViewController ()

@property (nonatomic, retain) UINavigationController * navigationController;

@property (nonatomic, retain) TweetInfo * tweet;
@property (nonatomic, retain) UIWebView * tweetContentView;

@property (readonly) UITableViewCell * conversationCell;
@property (readonly) UITableViewCell * publicReplyCell;
@property (readonly) UITableViewCell * directMessageCell;
@property (readonly) UITableViewCell * retweetCell;
@property (readonly) MarkAsFavoriteCell * favoriteCell;
@property (readonly) UITableViewCell * deleteTweetCell;

- (void)displayTweet;
- (void)loadTweetWebView;

- (void)retweet;
- (void)sendReply;
- (void)sendDirectMessage;
- (void)toggleFavoriteValue;

- (void)displayComposerMailSheet;

- (void)fetchRemoteImage:(NSString *)avatarUrlString;

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)sectionForActualSection:(NSInteger)section;

- (void)confirmDeletion;

+ (UIImage *)defaultAvatar;

@end

@implementation TweetViewController

@synthesize delegate, navigationController, tweetContentView, tweet;
@synthesize showsExtendedActions, allowDeletion;
@synthesize realParentViewController;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;

    [headerView release];
    [fullNameLabel release];
    [usernameLabel release];
    
    [publicReplyCell release];
    [directMessageCell release];
    [retweetCell release];
    [favoriteCell release];
    [deleteTweetCell release];

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
    NSInteger numSections = NUM_SECTIONS;
    if (!showsFavoriteButton)
        numSections--;
    if (allowDeletion)
        numSections++;

    return numSections;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
    numberOfRowsInSection:(NSInteger)section
{
    NSInteger transformedSection = [self sectionForActualSection:section];
    NSInteger nrows = 0;
    switch (transformedSection) {
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
        case kTweetDeleteSection:
            nrows = NUM_TWEET_DELETE_ROWS;
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

    if (transformedPath.section == kTweetDetailsSection) {
        if (transformedPath.row == kTweetTextRow) {
            [tweetTextTableViewCell.contentView addSubview:tweetContentView];
            cell = tweetTextTableViewCell;
        } else if (indexPath.row == kConversationRow) {
            cell = self.conversationCell;
            NSString * formatString =
                NSLocalizedString(@"tweetdetailsview.inreplyto.formatstring",
                @"");
            cell.textLabel.text =
                [NSString stringWithFormat:formatString,
                tweet.inReplyToTwitterUsername];
        }
    } else if (transformedPath.section == kComposeActionsSection) {
        if (transformedPath.row == kPublicReplyRow)
            cell = self.publicReplyCell;
        else if (transformedPath.row == kDirectMessageRow)
            cell = self.directMessageCell;
        else if (transformedPath.row == kRetweetRow)
            cell = self.retweetCell;
    } else if (transformedPath.section == kTweetActionsSection) {
        cell = self.favoriteCell;
        [self.favoriteCell setMarkedState:[tweet.favorited boolValue]];
        [self.favoriteCell setUpdatingState:markingFavorite];
    } else // delete section
        cell = self.deleteTweetCell;

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
        [self toggleFavoriteValue];
    else if (transformedPath.section == kTweetDeleteSection) {
        [self confirmDeletion];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

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
    if (sheet.tag == kTweetActionSheetActions) {
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
    } else if (buttonIndex == 0) { // delete tweet
        [self.navigationController popViewControllerAnimated:YES];
        [delegate deleteTweet:tweet.identifier];
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
        [NSString stringWithFormat:@"\"%@\"\n- %@\n\n%@", self.tweet.text,
        self.tweet.user.username, [tweet tweetUrl]];
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

- (UITableViewCell *)conversationCell
{
    if (!conversationCell) {
        conversationCell =
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        conversationCell.accessoryType =
            UITableViewCellAccessoryDisclosureIndicator;
    }

    return conversationCell;
}

- (UITableViewCell *)publicReplyCell
{
    if (!publicReplyCell) {
        publicReplyCell = 
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        publicReplyCell.textLabel.text =
            NSLocalizedString(@"tweetdetailsview.publicreply.label", @"");
        publicReplyCell.imageView.image =
            [UIImage imageNamed:@"PublicReplyButtonIcon.png"];
        publicReplyCell.imageView.highlightedImage =
            [UIImage imageNamed:@"PublicReplyButtonIconHighlighted.png"];
    }
    
    return publicReplyCell;
}

- (UITableViewCell *)directMessageCell
{
    if (!directMessageCell) {
        directMessageCell =
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        directMessageCell.textLabel.text =
            NSLocalizedString(@"tweetdetailsview.directmessage.label", @"");
        directMessageCell.imageView.image =
            [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
        directMessageCell.imageView.highlightedImage =
            [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
    }

    return directMessageCell;
}

- (UITableViewCell *)retweetCell
{
    if (!retweetCell) {
        retweetCell = 
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        retweetCell.textLabel.text =
            NSLocalizedString(@"tweetdetailsview.retweet.label", @"");
        retweetCell.imageView.image = [UIImage imageNamed:@"RetweetButtonIcon.png"];
        retweetCell.imageView.highlightedImage =
            [UIImage imageNamed:@"RetweetButtonIconHighlighted.png"];
    }

    return retweetCell;
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

    UIImage * avatar = [tweet.user fullAvatar];
    if (!avatar)
        avatar = [tweet.user thumbnailAvatar];
    if (!avatar)
        avatar = [[self class] defaultAvatar];

    [avatarImage setImage:avatar];

    [self fetchRemoteImage:tweet.user.avatar.fullImageUrl];
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

- (UITableViewCell *)deleteTweetCell
{
    if (!deleteTweetCell) {
        deleteTweetCell =
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        deleteTweetCell.textLabel.text =
            NSLocalizedString(@"tweetdetailsview.deletetweet.label", @"");
        deleteTweetCell.imageView.image =
            [UIImage imageNamed:@"DeleteTweetButtonIcon.png"];
    }

    return deleteTweetCell;
}

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row =
        indexPath.section == kComposeActionsSection &&
        indexPath.row == kPublicReplyRow && !showsExtendedActions ?
        kDirectMessageRow : indexPath.row;
    NSInteger section = [self sectionForActualSection:indexPath.section];

    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSInteger)sectionForActualSection:(NSInteger)section
{
    NSInteger transformedSection;
    switch (section) {
        case 0:
            transformedSection = kTweetDetailsSection;
            break;
        case 1:
            transformedSection = kComposeActionsSection;
            break;
        case 2:
            transformedSection =
                showsFavoriteButton ?
                kTweetActionsSection : kTweetDeleteSection;
            break;
        case 3:
            transformedSection = kTweetDeleteSection;
            break;
    }

    return transformedSection;
}

- (void)confirmDeletion
{
    NSString * cancel =
        NSLocalizedString(@"tweetdetailsview.deletetweet.cancel", @"");
    NSString * delete =
        NSLocalizedString(@"tweetdetailsview.deletetweet.confirm", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:self
        cancelButtonTitle:cancel destructiveButtonTitle:delete
        otherButtonTitles:nil];
    sheet.tag = kTweetActionSheetDeleteConfirmation;

    UIView * rootView =
        navigationController.parentViewController.view;
    [sheet showInView:rootView];
}

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;

    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar.png"] retain];

    return defaultAvatar;
}

@end
