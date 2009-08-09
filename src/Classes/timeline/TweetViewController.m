//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TweetViewController.h"
#import "TweetTextTableViewCell.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIAlertView+InstantiationAdditions.h"
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
- (NSString *)reuseIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)createCellForRowAtIndexPath:(NSIndexPath *)indexPath
                                 reuseIdentifier:(NSString *)reuseIdentifier;

- (void)displayTweet;

- (void)retweet;
- (void)sendPublicReply;
- (void)sendDirectMessage;
- (void)toggleFavoriteValue;

- (void)displayComposerMailSheet;

- (void)fetchRemoteImage:(NSString *)avatarUrlString;

- (void)configureCell:(UITableViewCell *)cell asFavorite:(BOOL)favorite;

+ (UIImage *)defaultAvatar;

@property (nonatomic, retain) UIWebView * tweetContentView;

@end

@implementation TweetViewController

@synthesize delegate, selectedTweet, avatar, tweetContentView;

- (void)dealloc
{
    self.delegate = nil;

    [headerView release];
    [fullNameLabel release];
    [usernameLabel release];

    self.selectedTweet = nil;
    self.avatar = nil;
    self.tweetContentView = nil;

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    tweetTextTableViewCell =
        [[TweetTextTableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:@"TweetTextTableViewCell"];
    tweetTextTableViewCell.webView.delegate = self;

    self.tableView.tableHeaderView = headerView;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 300, 0, 0);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView flashScrollIndicators];
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
    NSInteger nrows = 0;
    switch (section) {
        case kTweetDetailsSection:
            nrows = selectedTweet.inReplyToTwitterTweetId ?
                NUM_TWEET_DETAILS_ROWS : NUM_TWEET_DETAILS_ROWS - 1;
            break;
        case kComposeActionsSection:
            nrows = NUM_COMPOSE_ACTION_ROWS;
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
                selectedTweet.inReplyToTwitterUsername];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == kComposeActionsSection) {
        NSString * text = nil;
        UIImage * image = nil;

        if (indexPath.row == kPublicReplyRow) {
            text =
                NSLocalizedString(@"tweetdetailsview.publicreply.label", @"");
            image = [UIImage imageNamed:@"PublicReplyButtonIcon.png"];
        } else if (indexPath.row == kDirectMessageRow) {
            text =
                NSLocalizedString(@"tweetdetailsview.directmessage.label", @"");
            image = [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
        } else if (indexPath.row == kRetweetRow) {
            text = NSLocalizedString(@"tweetdetailsview.retweet.label", @"");
            image = [UIImage imageNamed:@"RetweetButtonIcon.png"];
        }

        cell.textLabel.text = text;
        cell.imageView.image = image;
    } else if (indexPath.section == kTweetActionsSection)
        if (indexPath.row == kFavoriteRow) {
            BOOL favorite = [selectedTweet.favorited boolValue];
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
                [selectedTweet.inReplyToTwitterTweetId description];
            NSString * replyToUsername =
                selectedTweet.inReplyToTwitterUsername;
            [delegate loadNewTweetWithId:tweetId username:replyToUsername];
        }
    } else if (indexPath.section == kComposeActionsSection) {
        if (indexPath.row == kPublicReplyRow)
            [self sendPublicReply];
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
            NSString * replyToUsername =
                self.selectedTweet.inReplyToTwitterUsername;
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

- (void)displayTweet:(TweetInfo *)tweet avatar:(UIImage *)anAvatar
   withPreLoadedView:(UIWebView *)view
{
    self.selectedTweet = tweet;
    self.avatar = anAvatar;

    [self.tweetContentView removeFromSuperview];
    self.tweetContentView = view;
    self.tweetContentView.delegate = self;

    [self displayTweet];
}

- (void)setUsersTweet:(BOOL)usersTweet
{
    // ignore for now
}

- (void)hideFavoriteButton:(BOOL)hide
{
    // ignore for now
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
                self.selectedTweet.user, self.selectedTweet.identifier];
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
        [self.selectedTweet.text stringByMatching:subjectRegex];
    if (subject && ![subject isEqual:@""])
        subject = [NSString stringWithFormat:@"%@...", subject];
    else
        subject = self.selectedTweet.text;
    [picker setSubject:subject];

    NSString * webAddress =
         [NSString stringWithFormat:@"http://twitter.com/%@/status/%@",
         self.selectedTweet.user, self.selectedTweet.identifier];
    NSString * body =
        [NSString stringWithFormat:@"%@\n\n%@", self.selectedTweet.text,
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
    [delegate showTweetsForUser:selectedTweet.user.username];
}

- (IBAction)showFullProfileImage:(id)sender
{
    User * selectedUser = selectedTweet.user;

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

- (void)sendPublicReply
{
    [delegate replyToTweet];
}

- (void)sendDirectMessage
{
    [delegate sendDirectMessageToUser:selectedTweet.user.username];
}

- (void)toggleFavoriteValue
{
    BOOL favorite = [selectedTweet.favorited boolValue];
    favorite = !favorite;
    [delegate setFavorite:favorite];
    selectedTweet.favorited = [NSNumber numberWithBool:favorite];

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

    if (indexPath.section == kTweetDetailsSection &&
        indexPath.row == kTweetTextRow) {
        tweetTextTableViewCell =
            [[TweetTextTableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
          reuseIdentifier:reuseIdentifier];
        tweetTextTableViewCell.webView.delegate = self;
        cell = tweetTextTableViewCell;
    } else
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:reuseIdentifier] autorelease];

    return cell;
}

- (void)displayTweet
{
    if (selectedTweet.user.name.length > 0) {
        usernameLabel.text = selectedTweet.user.username;
        fullNameLabel.text = selectedTweet.user.name;
    } else {
        usernameLabel.text = @"";
        fullNameLabel.text = selectedTweet.user.username;
    }

    if (!self.avatar) {
        [self fetchRemoteImage:selectedTweet.user.profileImageUrl];
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
