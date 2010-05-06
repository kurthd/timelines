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
#import "Tweet+GeneralHelpers.h"
#import "TweetLocation+GeneralHelpers.h"
#import "SettingsReader.h"
#import "TwitbitShared.h"
#import "CommonTwitterServicePhotoSource.h"

static NSString * usernameRegex = @"x-twitbit://user\\?screen_name=@([\\w_]+)";
static NSString * hashRegex = @"x-twitbit://search\\?query=(.+)";

const CGFloat WEB_VIEW_WIDTH = 290;

static const NSInteger NUM_SECTIONS = 2;
enum Sections {
    kTweetDetailsSection,
    kTweetActionsSection
};

static const NSInteger NUM_TWEET_DETAILS_ROWS = 1;
enum TweetDetailsRows {
    kTweetTextRow,
    kLocationRow,
    kConversationRow,
    kRetweetAuthorRow
};

static const NSInteger NUM_TWEET_ACTION_ROWS = 4;
enum TweetActionRows {
    kPublicReplyRow,
    kRetweetRow,
    kQuoteRow,
    kFavoriteRow,
    kDeleteRow
};

enum TweetActionSheets {
    kTweetActionSheetActions,
    kTweetActionSheetDeleteConfirmation
};

@interface TweetViewController ()

@property (nonatomic, retain) UINavigationController * navigationController;

@property (nonatomic, retain) Tweet * tweet;
@property (nonatomic, retain) UIWebView * tweetContentView;

@property (readonly) UITableViewCell * conversationCell;
@property (readonly) ActionButtonCell * publicReplyCell;
@property (readonly) RetweetCell * retweetCell;
@property (readonly) ActionButtonCell * quoteCell;
@property (readonly) MarkAsFavoriteCell * favoriteCell;
@property (readonly) ActionButtonCell * deleteTweetCell;
@property (readonly) UITableViewCell * retweetAuthorCell;

@property (nonatomic, retain) AsynchronousNetworkFetcher * photoPreviewFetcher;

- (void)displayTweetOnView;
- (void)loadTweetWebView;

- (void)retweet;
- (void)sendReply;
- (void)toggleFavoriteValue;

- (void)fetchRemoteImage:(NSString *)avatarUrlString;

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)sectionForActualSection:(NSInteger)section;

- (void)confirmDeletion;

- (Tweet *)displayTweet;

- (void)setPhotoPreviewInWebView:(NSString *)photoUrl;

+ (UIImage *)defaultAvatar;

@end

@implementation TweetViewController

@synthesize delegate, navigationController, tweetContentView, tweet;
@synthesize allowDeletion;
@synthesize realParentViewController;
@synthesize photoPreviewFetcher;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;

    [headerView release];
    [headerBackgroundView release];
    [headerTopLine release];
    [headerViewPadding release];
    [chatArrowView release];
    [footerView release];
    [openInBrowserButton release];
    [emailButton release];
    [fullNameLabel release];
    [usernameLabel release];

    [locationCell release];
    [publicReplyCell release];
    [retweetCell release];
    [quoteCell release];
    [favoriteCell release];
    [deleteTweetCell release];
    [retweetAuthorCell release];

    [tweetTextTableViewCell release];
    self.tweetContentView = nil;

    self.tweet = nil;

    [photoPreviewFetcher release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    tweetTextTableViewCell =
        [[TweetTextTableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:@"TweetTextTableViewCell"];

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.tableView.separatorColor = [UIColor twitchGrayColor];

        headerBackgroundView.image =
            [UIImage imageNamed:@"UserHeaderDarkThemeGradient.png"];

        headerTopLine.backgroundColor = [UIColor blackColor];
        headerViewPadding.backgroundColor = [UIColor defaultDarkThemeCellColor];

        chatArrowView.image = [UIImage imageNamed:@"DarkThemeChatArrow.png"];

        self.view.backgroundColor =
            [UIColor colorWithPatternImage:
            [UIImage imageNamed:@"DarkThemeBackground.png"]];

        UIImage * buttonImage =
            [[UIImage imageNamed:@"DarkThemeButtonBackground.png"]
            stretchableImageWithLeftCapWidth:10 topCapHeight:0];
        [emailButton setBackgroundImage:buttonImage
            forState:UIControlStateNormal];
        [openInBrowserButton setBackgroundImage:buttonImage
            forState:UIControlStateNormal];
        [emailButton setTitleColor:[UIColor twitchBlueOnDarkBackgroundColor]
            forState:UIControlStateNormal];
        [openInBrowserButton
            setTitleColor:[UIColor twitchBlueOnDarkBackgroundColor]
            forState:UIControlStateNormal];
        
        fullNameLabel.textColor = [UIColor whiteColor];
        fullNameLabel.shadowColor = [UIColor blackColor];

        usernameLabel.textColor = [UIColor lightGrayColor];
        usernameLabel.shadowColor = [UIColor blackColor];
        
        tweetTextTableViewCell.backgroundColor =
            [UIColor defaultDarkThemeCellColor];
    }

    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = footerView;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 300, 0, 0);

    if (self.navigationItem && self.navigationItem.title.length == 0)
        self.navigationItem.title =
            NSLocalizedString(@"tweetdetailsview.title", @"");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [delegate showingTweetDetails:self];
    
    // this fixes a bug in the dimensions when the app loads on this view
    self.view.frame = CGRectMake(0, 0, 320, 416);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    dismissedView = YES;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return NUM_SECTIONS;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tv
    numberOfRowsInSection:(NSInteger)section
{
    NSInteger transformedSection = [self sectionForActualSection:section];
    NSInteger nrows = 0;
    switch (transformedSection) {
        case kTweetDetailsSection:
            nrows = NUM_TWEET_DETAILS_ROWS;
            if ([self displayTweet].inReplyToTwitterTweetId)
                nrows++;
            if ([self displayTweet].location)
                nrows++;
            if (self.tweet.retweet)
                nrows++;
            break;
        case kTweetActionsSection:
            nrows = NUM_TWEET_ACTION_ROWS;
            if (!showsFavoriteButton)
                nrows--;
            break;
    }

    return nrows;
}

- (CGFloat)tableView:(UITableView *)tv
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = 44;

    NSIndexPath * transformedPath = [self indexForActualIndexPath:indexPath];

    if (transformedPath.section == kTweetDetailsSection &&
        transformedPath.row == kTweetTextRow) {
        CGFloat tweetTextHeight = tweetContentView.frame.size.height;
        rowHeight = tweetTextHeight > 63 ? tweetTextHeight : 63;
    } else if (transformedPath.section == kTweetDetailsSection &&
        transformedPath.row == kLocationRow)
        rowHeight = 64;

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
        } else if (transformedPath.row == kConversationRow) {
            cell = self.conversationCell;
            NSString * formatString =
                NSLocalizedString(@"tweetdetailsview.inreplyto.formatstring",
                @"");
            cell.textLabel.text =
                [NSString stringWithFormat:formatString,
                [self displayTweet].inReplyToTwitterUsername];
        } else if (transformedPath.row == kLocationRow) {
            [self.locationCell setLandscape:NO];
            cell = self.locationCell;
        } else if (transformedPath.row == kRetweetAuthorRow) {
            cell = self.retweetAuthorCell;
            NSString * formatString =
                NSLocalizedString(@"tweetdetailsview.retweet.formatstring",
                @"");
            cell.textLabel.text =
                [NSString stringWithFormat:formatString,
                self.tweet.user.username];
        }
    } else if (transformedPath.section == kTweetActionsSection) {
        if (transformedPath.row == kPublicReplyRow)
            cell = self.publicReplyCell;
        else if (transformedPath.row == kRetweetRow)
            cell = self.retweetCell;
        else if (transformedPath.row == kQuoteRow)
            cell = self.quoteCell;
        else if (transformedPath.row == kFavoriteRow) {
            cell = self.favoriteCell;
            [self.favoriteCell
                setMarkedState:[[self displayTweet].favorited boolValue]];
            [self.favoriteCell setUpdatingState:markingFavorite];
        } else if (transformedPath.row == kDeleteRow)
            cell = self.deleteTweetCell;
    }

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * transformedPath = [self indexForActualIndexPath:indexPath];

    if (transformedPath.section == kTweetDetailsSection) {
        if (transformedPath.row == kConversationRow)
            [delegate
                loadConversationFromTweetId:[self displayTweet].identifier];
        else if (transformedPath.row == kRetweetAuthorRow)
            [delegate showUserInfoForUser:self.tweet.user];
        else if (transformedPath.row == kLocationRow) {
            CLLocation * location = [[self displayTweet].location asCllocation];
            CLLocationCoordinate2D coord = location.coordinate;
            NSString * locationAsString =
                [NSString stringWithFormat:@"%f, %f", coord.latitude,
                coord.longitude];
            [delegate showLocationOnMap:locationAsString];
        }
    } else if (transformedPath.section == kTweetActionsSection) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (transformedPath.row == kPublicReplyRow)
            [self sendReply];
        else if (transformedPath.row == kRetweetRow) {
            [delegate retweetNativelyWithTwitter];
            [self.retweetCell setUpdatingState:YES];
        }
        else if (transformedPath.row == kQuoteRow)
            [self retweet];
        else if (transformedPath.row == kFavoriteRow)
            [self toggleFavoriteValue];
        else if (transformedPath.row == kDeleteRow)
            [self confirmDeletion];
    }
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView *)view
{
    // first shrink the frame so 'sizeThatFits' calculates properly
    CGFloat width = WEB_VIEW_WIDTH;
    CGRect frame = CGRectMake(5, 0, width, 31);

    tweetContentView.frame = frame;

    CGSize size = [tweetContentView sizeThatFits:CGSizeZero];

    frame.size.width = size.width;
    frame.size.height = size.height;
    tweetContentView.frame = frame;

    // remove from UIWindow's key window
    [tweetContentView removeFromSuperview];
    [tweetTextTableViewCell.contentView addSubview:tweetContentView];

    if (navigationController && !dismissedView &&
        self.parentViewController != navigationController)
        [navigationController pushViewController:self animated:YES];

    [self displayTweetOnView];

    SEL sel = @selector(tweetViewController:finishedLoadingTweet:);
    if ([self.delegate respondsToSelector:sel])
        [self.delegate tweetViewController:self
                      finishedLoadingTweet:self.tweet];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([error code] != NSURLErrorCancelled)
        NSLog(@"Tweet web view '%@' failed to load request: '%@' error: '%@'",
            webView, webView.request, error);
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
                [webpage stringByMatching:usernameRegex capture:1];
            NSLog(@"Showing user info for user: %@", username);
            [delegate showUserInfoForUsername:username];
        } else if ([webpage isMatchedByRegex:hashRegex]) {
            NSString * query =
                [webpage stringByMatching:hashRegex capture:1];
            NSLog(@"Showing search results for '%@'", query);
            [delegate showResultsForSearch:query];
        } else if (inReplyToString = [webpage stringByMatching:@"#\\d*"]) {
            NSString * tweetIdString = [inReplyToString substringFromIndex:1];
            NSNumber * tweetId =
                [NSNumber numberWithLongLong:[tweetIdString longLongValue]];
            NSString * replyToUsername =
                [self displayTweet].inReplyToTwitterUsername;
            [delegate loadNewTweetWithId:tweetId username:replyToUsername
                animated:YES];
        } else if ([webpage isTwitterUrl]) {
            NSNumber * tweetId = [webpage tweetIdFromTwitterUrl];
            NSString * username = [webpage twitterUsernameFromTwitterUrl];

            [delegate loadNewTweetWithId:tweetId
                                username:username
                                animated:YES];
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
            [remotePhoto release];
        } else
            [[TwitchWebBrowserDisplayMgr instance] visitWebpage:webpage];
    }

    return navigationType != UIWebViewNavigationTypeLinkClicked;
}

#pragma mark Public interface implementation

- (void)displayTweet:(Tweet *)aTweet
    onNavigationController:(UINavigationController *)navController
{
    dismissedView = NO;

    // sucks but the map span doesn't seem to set properly if we don't recreate
    if (locationCell) {
        [locationCell release];
        locationCell = nil;
    }

    self.tweet = aTweet;
    self.navigationController = navController;

    NSString * photoUrlString = [[self displayTweet] photoUrlWebpage];
    if (photoUrlString && ![[self displayTweet] photoUrl]) {
        NSLog(@"Fetching photo preview: %@", photoUrlString);
        NSURL * photoUrl = [NSURL URLWithString:photoUrlString];
        static NSString * directImageRegex =
            @"\\S+\\.jpg$|\\S+\\.jpeg$|\\S+\\.bmp|\\S+\\.gif|\\S+\\.png";
        if ([photoUrlString stringByMatching:directImageRegex])
            [self performSelector:@selector(setPhotoPreviewInWebView:)
            withObject:photoUrlString afterDelay:0.7];
        else
            self.photoPreviewFetcher =
                [AsynchronousNetworkFetcher fetcherWithUrl:photoUrl
                delegate:self];
    }

    [self loadTweetWebView];

    if ([self displayTweet].location)
        [self.locationCell
            setLocation:[[self displayTweet].location asCllocation]];
}

- (void)setFavorited:(BOOL)favorited
{
    [self.favoriteCell setMarkedState:favorited];
    [self.favoriteCell setUpdatingState:NO];
    markingFavorite = NO;
}

- (void)setSentRetweet
{
    [self.retweetCell setUpdatingState:NO];
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
    if (buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        [delegate deleteTweet:self.tweet.identifier];
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

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * urlAsString = [url absoluteString];
    if (fetcher == self.photoPreviewFetcher) {
        NSString * html =
            [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
            autorelease];
        NSString * photoUrl =
            [CommonTwitterServicePhotoSource photoUrlFromPageHtml:html
            url:urlAsString];
        NSLog(@"Received photo webpage; photo url is: %@", photoUrl);
        if (photoUrl)
            [self setPhotoPreviewInWebView:photoUrl];
    } else {
        NSLog(@"Received avatar for url: %@", url);
        UIImage * avatar = [UIImage imageWithData:data];
        [User setAvatar:avatar forUrl:urlAsString];
        NSRange notFoundRange = NSMakeRange(NSNotFound, 0);
        if (NSEqualRanges([urlAsString rangeOfString:@"_normal."],
            notFoundRange) &&
            avatar &&
            ([[self displayTweet].user.avatar.thumbnailImageUrl
            isEqual:urlAsString] ||
            [[self displayTweet].user.avatar.fullImageUrl isEqual:urlAsString]))
            [avatarImage setImage:avatar];
    }
}

- (void)setPhotoPreviewInWebView:(NSString *)photoUrl
{
    [[self displayTweet] setPhotoUrl:photoUrl];
    [tweetContentView
        loadHTMLStringRelativeToMainBundle:
        [[self displayTweet] textAsHtml]];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark Tweet actions

- (IBAction)showUserTweets:(id)sender
{
    [delegate showUserInfoForUser:[self displayTweet].user];
}

- (IBAction)showFullProfileImage:(id)sender
{
    User * selectedUser = [self displayTweet].user;

    NSString * url = selectedUser.avatar.fullImageUrl;
    UIImage * remoteAvatar =
        [UIImage imageWithData:selectedUser.avatar.fullImage];

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:remoteAvatar url:url name:selectedUser.name];
    [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
}

- (IBAction)openTweetInBrowser
{
    NSString * webAddress = [tweet tweetUrl];
    NSLog(@"Opening tweet in browser (%@)...", webAddress);
    [[TwitchWebBrowserDisplayMgr instance] visitWebpage:webAddress];
}

- (IBAction)sendInEmail
{
    NSLog(@"Sending tweet in email...");
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController * picker =
            [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;

        static NSString * subjectRegex = @"\\S+\\s\\S+\\s\\S+\\s\\S+\\s\\S+";
        NSString * subject =
            [[self displayTweet].text stringByMatching:subjectRegex];
        if (subject && ![subject isEqual:@""])
            subject = [NSString stringWithFormat:@"%@...", subject];
        else
            subject = [self displayTweet].text;
        [picker setSubject:subject];

        NSString * body =
            [NSString stringWithFormat:@"\"%@\"\n- %@\n\n%@",
            [self displayTweet].text,
            [self displayTweet].user.username, [tweet tweetUrl]];
        [picker setMessageBody:body isHTML:NO];

        [self.realParentViewController presentModalViewController:picker
            animated:YES];

        [picker release];
    } else {
        NSString * title =
            NSLocalizedString(@"photobrowser.unabletosendmail.title", @"");
        NSString * message =
            NSLocalizedString(@"photobrowser.unabletosendmail.message", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title
            message:message];
        [alert show];
    }
}

- (void)retweet
{
    [delegate reTweetSelected];
}

- (void)sendReply
{
    [delegate replyToTweet];
}

- (void)toggleFavoriteValue
{
    if (!markingFavorite) {
        markingFavorite = YES;
        [self.favoriteCell setUpdatingState:YES];
        [delegate setFavorite:![[self displayTweet].favorited boolValue]];
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

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            conversationCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            conversationCell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return conversationCell;
}

- (UITableViewCell *)retweetAuthorCell
{
    if (!retweetAuthorCell) {
        retweetAuthorCell =
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        retweetAuthorCell.accessoryType =
            UITableViewCellAccessoryDisclosureIndicator;

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            retweetAuthorCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            retweetAuthorCell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return retweetAuthorCell;
}

- (UITableViewCell *)publicReplyCell
{
    if (!publicReplyCell) {
        UIColor * bColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor defaultDarkThemeCellColor] : [UIColor whiteColor];
        publicReplyCell = 
            [[ActionButtonCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""
            backgroundColor:bColor];
        NSString * actionText =
            NSLocalizedString(@"tweetdetailsview.publicreply.label", @"");
        [publicReplyCell setActionText:actionText];
        UIImage * actionImage =
            [UIImage imageNamed:@"PublicReplyButtonIcon.png"];
        [publicReplyCell setActionImage:actionImage];
    }

    return publicReplyCell;
}

- (UITableViewCell *)quoteCell
{
    if (!quoteCell) {
        UIColor * bColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor defaultDarkThemeCellColor] : [UIColor whiteColor];
        quoteCell =
            [[ActionButtonCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""
            backgroundColor:bColor];
        NSString * actionText =
            NSLocalizedString(@"tweetdetailsview.quote.label", @"");
        [quoteCell setActionText:actionText];
        UIImage * actionImage = [UIImage imageNamed:@"QuoteButtonIcon.png"];
        [quoteCell setActionImage:actionImage];
    }

    return quoteCell;
}

- (void)loadTweetWebView
{
    CGFloat width = WEB_VIEW_WIDTH;
    CGRect frame = CGRectMake(5, 0, width, 1);

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

    NSString * html = [[self displayTweet] textAsHtml];
    [tweetContentView loadHTMLStringRelativeToMainBundle:html];
}

- (void)displayTweetOnView
{
    if ([self displayTweet].user.name.length > 0) {
        usernameLabel.text =
            [NSString stringWithFormat:@"@%@",
            [self displayTweet].user.username];
        fullNameLabel.text = [self displayTweet].user.name;
    } else {
        usernameLabel.text = @"";
        fullNameLabel.text = [self displayTweet].user.username;
    }

    UIImage * avatar = [[self displayTweet].user fullAvatar];
    if (!avatar) {
        avatar = [[self displayTweet].user thumbnailAvatar];
        [self fetchRemoteImage:[self displayTweet].user.avatar.fullImageUrl];
    }
    if (!avatar) {
        avatar = [[self class] defaultAvatar];
        [self fetchRemoteImage:[self displayTweet].user.avatar.thumbnailImageUrl];
    }

    [avatarImage setImage:avatar];

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

- (UITableViewCell *)retweetCell
{
    if (!retweetCell) {
        NSArray * nib =
            [[[NSBundle mainBundle] loadNibNamed:@"RetweetCell"
            owner:self options:nil] retain];

         retweetCell = [nib objectAtIndex:0];
         if ([SettingsReader displayTheme] == kDisplayThemeDark) {
             retweetCell.backgroundColor = [UIColor defaultDarkThemeCellColor];
             retweetCell.textLabel.textColor = [UIColor whiteColor];
         }
         [retweetCell setUpdatingState:NO];
    }

    return retweetCell;
}

- (MarkAsFavoriteCell *)favoriteCell
{
    if (!favoriteCell) {
        NSArray * nib =
            [[[NSBundle mainBundle] loadNibNamed:@"MarkAsFavoriteCell"
            owner:self options:nil] retain];

         favoriteCell = [nib objectAtIndex:0];
         if ([SettingsReader displayTheme] == kDisplayThemeDark) {
             favoriteCell.backgroundColor = [UIColor defaultDarkThemeCellColor];
             favoriteCell.textLabel.textColor = [UIColor whiteColor];
         }
    }

    return favoriteCell;
}

- (UITableViewCell *)deleteTweetCell
{
    if (!deleteTweetCell) {
        UIColor * bColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor defaultDarkThemeCellColor] : [UIColor whiteColor];
        deleteTweetCell =
            [[ActionButtonCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""
            backgroundColor:bColor];
        NSString * actionText =
            NSLocalizedString(@"tweetdetailsview.deletetweet.label", @"");
        [deleteTweetCell setActionText:actionText];
        UIImage * actionIcon =
            [UIImage imageNamed:@"DeleteTweetButtonIcon.png"];
        [deleteTweetCell setActionImage:actionIcon];
    }

    return deleteTweetCell;
}

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)actual
{
    NSInteger row = actual.row;
    if (actual.section == kTweetDetailsSection) {
        if (row >= kLocationRow && ![self displayTweet].location)
            row++;
        if (row >= kConversationRow &&
            ![self displayTweet].inReplyToTwitterTweetId)
            row++;
    } else if (allowDeletion && row > kPublicReplyRow) // remove retweet cell
        row++;

    return [NSIndexPath indexPathForRow:row inSection:actual.section];
}

- (NSInteger)sectionForActualSection:(NSInteger)section
{    
    return section;
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
    sheet.actionSheetStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIActionSheetStyleBlackOpaque : UIActionSheetStyleDefault;

    [sheet showInView:rootView];
}

- (TweetLocationCell *)locationCell
{
    if (!locationCell) {
        locationCell =
            [[TweetLocationCell alloc] initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:@"TweetLocationCell"];
        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            locationCell.backgroundColor = [UIColor defaultDarkThemeCellColor];
            [locationCell setLabelTextColor:[UIColor whiteColor]];
        } else
            [locationCell setLabelTextColor:[UIColor blackColor]];
    }

    return locationCell;
}

- (Tweet *)displayTweet
{
    return self.tweet.retweet ? self.tweet.retweet : self.tweet;
}

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;

    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar.png"] retain];

    return defaultAvatar;
}

@end
