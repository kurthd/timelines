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
#import "RotatableTabBarController.h"
#import "Tweet+GeneralHelpers.h"
#import "TweetLocation+GeneralHelpers.h"
#import "SettingsReader.h"
#import "TwitbitShared.h"

static NSString * usernameRegex = @"x-twitbit://user\\?screen_name=@([\\w_]+)";
static NSString * hashRegex = @"x-twitbit://search\\?query=(.+)";

const CGFloat WEB_VIEW_WIDTH = 290;
const CGFloat WEB_VIEW_WIDTH_LANDSCAPE = 450;

static const NSInteger NUM_SECTIONS = 2;
enum Sections {
    kTweetDetailsSection,
    kTweetActionsSection
};

static const NSInteger NUM_TWEET_DETAILS_ROWS = 1;
enum TweetDetailsRows {
    kTweetTextRow,
    kLocationRow,
    kConversationRow
};

static const NSInteger NUM_TWEET_ACTION_ROWS = 3;
enum TweetActionRows {
    kPublicReplyRow,
    kRetweetRow,
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
@property (readonly) ActionButtonCell * retweetCell;
@property (readonly) MarkAsFavoriteCell * favoriteCell;
@property (readonly) ActionButtonCell * deleteTweetCell;

- (void)displayTweet;
- (void)loadTweetWebView;

- (void)retweet;
- (void)sendReply;
- (void)toggleFavoriteValue;

- (void)fetchRemoteImage:(NSString *)avatarUrlString;

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)sectionForActualSection:(NSInteger)section;

- (void)confirmDeletion;

- (void)updateButtonsForOrientation:(UIInterfaceOrientation)o;

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
    
    UIInterfaceOrientation orientation =
        [[RotatableTabBarController instance] interfaceOrientation];
    [self updateButtonsForOrientation:orientation];

    BOOL landscape = [[RotatableTabBarController instance] landscape];
    if (lastDisplayedInLandscape != landscape)
        [self loadTweetWebView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    lastDisplayedInLandscape = [[RotatableTabBarController instance] landscape];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self updateButtonsForOrientation:o];
    [self loadTweetWebView];
}

- (void)updateButtonsForOrientation:(UIInterfaceOrientation)o
{
    CGFloat buttonWidth;
    CGFloat emailButtonX;
    if (o == UIInterfaceOrientationPortrait ||
        o == UIInterfaceOrientationPortraitUpsideDown) {
        buttonWidth = 147;
        emailButtonX = 164;
    } else {
        buttonWidth = 227;
        emailButtonX = 244;
    }

    CGRect openInBrowserButtonFrame = openInBrowserButton.frame;
    openInBrowserButtonFrame.size.width = buttonWidth;
    openInBrowserButton.frame = openInBrowserButtonFrame;

    CGRect emailButtonFrame = emailButton.frame;
    emailButtonFrame.size.width = buttonWidth;
    emailButtonFrame.origin.x = emailButtonX;
    emailButton.frame = emailButtonFrame;
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
            if (tweet.inReplyToTwitterTweetId)
                nrows++;
            if (tweet.location)
                nrows++;
            break;
        case kTweetActionsSection:
            nrows = NUM_TWEET_ACTION_ROWS;
            if (!showsFavoriteButton)
                nrows--;
            if (!showsExtendedActions)
                nrows--;
            if (allowDeletion)
                nrows++;
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
                tweet.inReplyToTwitterUsername];
        } else if (transformedPath.row == kLocationRow) {
            BOOL landscape = [[RotatableTabBarController instance] landscape];
            [self.locationCell setLandscape:landscape];
            cell = self.locationCell;
        }
    } else if (transformedPath.section == kTweetActionsSection) {
        if (transformedPath.row == kPublicReplyRow)
            cell = self.publicReplyCell;
        else if (transformedPath.row == kRetweetRow)
            cell = self.retweetCell;
        else if (transformedPath.row == kFavoriteRow) {
            cell = self.favoriteCell;
            [self.favoriteCell setMarkedState:[tweet.favorited boolValue]];
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
            [delegate loadConversationFromTweetId:tweet.identifier];
        else if (transformedPath.row == kLocationRow) {
            CLLocation * location = [tweet.location asCllocation];
            CLLocationCoordinate2D coord = location.coordinate;
            NSString * locationAsString =
                [NSString stringWithFormat:@"%f, %f", coord.latitude,
                coord.longitude];
            [delegate showLocationOnMap:locationAsString];
        }
    } else if (transformedPath.section == kTweetActionsSection) {
        [self.tableView deselectRowAtIndexPath:transformedPath animated:YES];
        if (transformedPath.row == kPublicReplyRow)
            [self sendReply];
        else if (transformedPath.row == kRetweetRow)
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
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    CGFloat width = !landscape ? WEB_VIEW_WIDTH : WEB_VIEW_WIDTH_LANDSCAPE;
    CGRect frame = CGRectMake(5, 0, width, 31);

    tweetContentView.frame = frame;

    CGSize size = [tweetContentView sizeThatFits:CGSizeZero];

    frame.size.width = size.width;
    frame.size.height = size.height;
    tweetContentView.frame = frame;

    // remove from UIWindow's key window
    [tweetContentView removeFromSuperview];
    [tweetTextTableViewCell.contentView addSubview:tweetContentView];

    if (navigationController &&
        self.parentViewController != navigationController)
        [navigationController pushViewController:self animated:YES];

    [self displayTweet];

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
    // sucks but the map span doesn't seem to set properly if we don't recreate
    if (locationCell) {
        [locationCell release];
        locationCell = nil;
    }

    self.tweet = aTweet;
    self.navigationController = navController;

    [self loadTweetWebView];

    if (self.tweet.location)
        [self.locationCell setLocation:[self.tweet.location asCllocation]];
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
    if (buttonIndex == 0) {
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
        avatar &&
        ([tweet.user.avatar.thumbnailImageUrl isEqual:urlAsString] ||
        [tweet.user.avatar.fullImageUrl isEqual:urlAsString]))
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

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            conversationCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            conversationCell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return conversationCell;
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

- (UITableViewCell *)retweetCell
{
    if (!retweetCell) {
        UIColor * bColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor defaultDarkThemeCellColor] : [UIColor whiteColor];
        retweetCell = 
            [[ActionButtonCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""
            backgroundColor:bColor];
        NSString * actionText =
            NSLocalizedString(@"tweetdetailsview.retweet.label", @"");
        [retweetCell setActionText:actionText];
        UIImage * actionImage =
            [UIImage imageNamed:@"RetweetButtonIconHighlighted.png"];
        [retweetCell setActionImage:actionImage];
    }

    return retweetCell;
}

- (void)loadTweetWebView
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    CGFloat width = !landscape ? WEB_VIEW_WIDTH : WEB_VIEW_WIDTH_LANDSCAPE;
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
    if (!avatar) {
        avatar = [tweet.user thumbnailAvatar];
        [self fetchRemoteImage:tweet.user.avatar.fullImageUrl];
    }
    if (!avatar) {
        avatar = [[self class] defaultAvatar];
        [self fetchRemoteImage:tweet.user.avatar.thumbnailImageUrl];
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
    NSInteger row;
    if (actual.section == kTweetDetailsSection && !tweet.location &&
        actual.row == kLocationRow)
        row = kConversationRow;
    else
        row = actual.row;

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

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;

    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar.png"] retain];

    return defaultAvatar;
}

@end
