//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageViewController.h"
#import "TweetTextTableViewCell.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "RegexKitLite.h"
#import "User+UIAdditions.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "PhotoBrowserDisplayMgr.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"
#import "UIColor+TwitchColors.h"
#import "DirectMessage+GeneralHelpers.h"

static NSString * usernameRegex = @"x-twitbit://user\\?screen_name=@([\\w_]+)";
static NSString * hashRegex = @"x-twitbit://search\\?query=(.+)";

const CGFloat TEXT_VIEW_WIDTH = 290;
const CGFloat TEXT_VIEW_WIDTH_LANDSCAPE = 450;

static const NSInteger NUM_SECTIONS = 2;
enum Sections {
    kTweetDetailsSection,
    kTweetActionsSection
};

static const NSInteger NUM_TWEET_DETAILS_ROWS = 1;
enum TweetDetailsRows {
    kTweetTextRow
};

static const NSInteger NUM_TWEET_ACTION_ROWS = 2;
enum TweetActionRows {
    kReplyRow,
    kDeleteRow
};

enum TweetActionSheets {
    kTweetActionSheetActions,
    kTweetActionSheetDeleteConfirmation
};

@interface DirectMessageViewController ()

@property (nonatomic, retain) UINavigationController * navigationController;

@property (nonatomic, retain) DirectMessage * directMessage;
@property (nonatomic, retain) UIWebView * tweetContentView;

@property (readonly) UITableViewCell * replyCell;
@property (readonly) UITableViewCell * deleteTweetCell;

- (void)displayDirectMessage;
- (void)loadTweetWebView;

- (void)sendReply;

- (void)fetchRemoteImage:(NSString *)avatarUrlString;

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)sectionForActualSection:(NSInteger)section;

- (void)confirmDeletion;

+ (UIImage *)defaultAvatar;

@end

@implementation DirectMessageViewController

@synthesize delegate, navigationController, tweetContentView, directMessage;
@synthesize realParentViewController;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;

    [headerView release];
    [headerBackgroundView release];
    [avatarBackgroundView release];
    [headerTopLine release];
    [headerBottomLine release];
    [headerViewPadding release];
    [chatArrowView release];
    [footerView release];
    [fullNameLabel release];
    [usernameLabel release];
    [emailButton release];
    
    [replyCell release];
    [deleteTweetCell release];

    [tweetTextTableViewCell release];
    self.tweetContentView = nil;

    self.directMessage = nil;

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
    self.tableView.tableFooterView = footerView;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 300, 0, 0);

    if (self.navigationItem && self.navigationItem.title.length == 0)
        self.navigationItem.title =
            NSLocalizedString(@"tweetdetailsview.title", @"");

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.tableView.separatorColor = [UIColor twitchGrayColor];

        headerBackgroundView.image =
            [UIImage imageNamed:@"UserHeaderDarkThemeGradient.png"];

        avatarBackgroundView.image =
            [UIImage imageNamed:@"AvatarDarkThemeBackground.png"];

        headerTopLine.backgroundColor = [UIColor blackColor];
        headerBottomLine.backgroundColor = [UIColor twitchGrayColor];
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
        
        [emailButton setTitleColor:[UIColor twitchBlueOnDarkBackgroundColor]
            forState:UIControlStateNormal];
        
        fullNameLabel.textColor = [UIColor whiteColor];
        fullNameLabel.shadowColor = [UIColor blackColor];

        usernameLabel.textColor = [UIColor lightGrayColor];
        usernameLabel.shadowColor = [UIColor blackColor];

        tweetTextTableViewCell.backgroundColor =
            [UIColor defaultDarkThemeCellColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [delegate showingTweetDetails:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self loadTweetWebView];
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
            break;
        case kTweetActionsSection:
            nrows = NUM_TWEET_ACTION_ROWS;
            if (usersDirectMessage)
                nrows--;
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

- (UITableViewCell *)tableView:(UITableView *)tv
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = nil;

    NSIndexPath * transformedPath = [self indexForActualIndexPath:indexPath];

    if (transformedPath.section == kTweetDetailsSection) {
        if (transformedPath.row == kTweetTextRow) {
            [tweetTextTableViewCell.contentView addSubview:tweetContentView];
            cell = tweetTextTableViewCell;
        }
    } else if (transformedPath.section == kTweetActionsSection) {
        if (transformedPath.row == kReplyRow)
            cell = self.replyCell;
        else if (transformedPath.row == kDeleteRow)
            cell = self.deleteTweetCell;
    }

    return cell;
}

- (void)tableView:(UITableView *)tv
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * transformedPath = [self indexForActualIndexPath:indexPath];

    if (transformedPath.section == kTweetActionsSection) {
        if (transformedPath.row == kReplyRow)
            [self sendReply];
        else if (transformedPath.row == kDeleteRow)
            [self confirmDeletion];
    }

    [self.tableView deselectRowAtIndexPath:transformedPath animated:YES];
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView *)view
{
    BOOL landscape =
        [[RotatableTabBarController instance] landscape];
    CGFloat width = !landscape ? TEXT_VIEW_WIDTH : TEXT_VIEW_WIDTH_LANDSCAPE;
    // first shrink the frame so 'sizeThatFits' calculates properly
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

    [self displayDirectMessage];
}

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(UIWebViewNavigationType)navigationType
{
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

- (void)displayDirectMessage:(DirectMessage *)dm
    onNavigationController:(UINavigationController *)navController
{
    self.directMessage = dm;
    self.navigationController = navController;

    [self loadTweetWebView];
}

- (void)setUsersDirectMessage:(BOOL)usersDirectMessageVal
{
    usersDirectMessage = usersDirectMessageVal;
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)sheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        [delegate deleteTweet:directMessage.identifier];
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
        ([directMessage.sender.avatar.thumbnailImageUrl isEqual:urlAsString] ||
        [directMessage.sender.avatar.fullImageUrl isEqual:urlAsString]))
        [avatarImage setImage:avatar];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark Tweet actions

- (IBAction)showUserTweets:(id)sender
{
    [delegate showUserInfoForUser:directMessage.sender];
}

- (IBAction)showFullProfileImage:(id)sender
{
    User * selectedUser = directMessage.sender;

    NSString * url = selectedUser.avatar.fullImageUrl;
    UIImage * remoteAvatar =
        [UIImage imageWithData:selectedUser.avatar.fullImage];

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:remoteAvatar url:url name:selectedUser.name];
    [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
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
            [self.directMessage.text stringByMatching:subjectRegex];
        if (subject && ![subject isEqual:@""])
            subject = [NSString stringWithFormat:@"%@...", subject];
        else
            subject = self.directMessage.text;
        [picker setSubject:subject];

        NSString * body =
            [NSString stringWithFormat:@"\"%@\"\n- %@", self.directMessage.text,
            self.directMessage.sender.username];
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

- (void)sendReply
{
    [delegate sendDirectMessageToUser:directMessage.sender.username];
}

#pragma mark Private implementation

- (UITableViewCell *)replyCell
{
    if (!replyCell) {
        replyCell = 
            [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
        replyCell.textLabel.text =
            NSLocalizedString(@"tweetdetailsview.reply.label", @"");
        replyCell.imageView.image =
            [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
        replyCell.imageView.highlightedImage =
            [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
            
        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            replyCell.backgroundColor = [UIColor defaultDarkThemeCellColor];
            replyCell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return replyCell;
}

- (void)loadTweetWebView
{
    BOOL landscape =
        [[RotatableTabBarController instance] landscape];
    CGFloat width = !landscape ? TEXT_VIEW_WIDTH : TEXT_VIEW_WIDTH_LANDSCAPE;
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

    NSString * html = [self.directMessage textAsHtml];
    [tweetContentView loadHTMLStringRelativeToMainBundle:html];
}

- (void)displayDirectMessage
{
    if (directMessage.sender.name.length > 0) {
        usernameLabel.text =
            [NSString stringWithFormat:@"@%@", directMessage.sender.username];
        fullNameLabel.text = directMessage.sender.name;
    } else {
        usernameLabel.text = @"";
        fullNameLabel.text = directMessage.sender.username;
    }

    UIImage * avatar = [directMessage.sender fullAvatar];
    if (!avatar)
        avatar = [directMessage.sender thumbnailAvatar];
    if (!avatar)
        avatar = [[self class] defaultAvatar];

    [avatarImage setImage:avatar];

    [self fetchRemoteImage:directMessage.sender.avatar.fullImageUrl];
    [self fetchRemoteImage:directMessage.sender.avatar.thumbnailImageUrl];

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

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            deleteTweetCell.backgroundColor =
                [UIColor defaultDarkThemeCellColor];
            deleteTweetCell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return deleteTweetCell;
}

- (NSIndexPath *)indexForActualIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if (indexPath.section == kTweetActionsSection &&
        indexPath.row == kReplyRow && usersDirectMessage)
        row = kDeleteRow;

    return [NSIndexPath indexPathForRow:row inSection:indexPath.section];
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

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;

    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar.png"] retain];

    return defaultAvatar;
}

@end
