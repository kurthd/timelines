//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetDetailsViewController.h"
#import "Tweet.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "NSDate+StringHelpers.h"
#import "AsynchronousNetworkFetcher.h"
#import "RegexKitLite.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface TweetDetailsViewController ()

- (void)setupWebView;
- (void)showWebView;
+ (NSString *)htmlForContent:(NSString *)content footer:(NSString *)footer;
+ (NSString *)htmlForContent:(NSString *)content footer:(NSString *)footer
    header:(NSString *)header;
+ (NSString *)bodyWithUserLinks:(NSString *)body;

@end

static NSString * usernameRegex = @"\\B(@[\\w_]+)";

@implementation TweetDetailsViewController

@synthesize delegate, selectedTweet;

- (void)dealloc
{
    [webView release];
    [favoriteButton release];
    [nameLabel release];
    [userTweetsButton release];
    [locationButton release];
    [avatar release];
    [deleteTweetButton release];
    [reTweetButton release];
    [footerView release];
    [footerGradient release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [delegate showingTweetDetails];
    webView.hidden = YES;
    [self performSelector:@selector(showWebView) withObject:nil afterDelay:0.1];
    if (self.selectedTweet) {
        [delegate setCurrentTweetDetailsUser:self.selectedTweet.user.username];
        [self setupWebView];
    }
    
    footerView.hidden = usersTweet;
    footerGradient.hidden = usersTweet;
    CGRect webViewFrame = webView.frame;
    if (usersTweet)
        webViewFrame.size.height = 292;
    else
        webViewFrame.size.height = 238;
    webView.frame = webViewFrame;
}

- (void)showWebView
{
    webView.hidden = NO;
}

- (void)setTweet:(TweetInfo *)tweet avatar:(UIImage *)avatarImage
{
    NSLog(@"Setting tweet");
    self.selectedTweet = tweet;

    [self setupWebView];

    nameLabel.text = tweet.user.name;
    [userTweetsButton
        setTitle:[NSString stringWithFormat:@"@%@", tweet.user.username]
        forState:UIControlStateNormal];

    if (!avatarImage) {
        NSURL * avatarUrl = [NSURL URLWithString:tweet.user.profileImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
        [avatar setImage:[UIImage imageNamed:@"DefaultAvatar.png"]];
    } else
        [avatar setImage:avatarImage];

    NSString * locationText = tweet.user.location;
    locationButton.hidden = !locationText || [locationText isEqual:@""];

    [locationButton setTitle:locationText forState:UIControlStateNormal];
    
    if (favorite = [tweet.favorited isEqual:[NSNumber numberWithInt:1]])
        [favoriteButton setImage:[UIImage imageNamed:@"Favorite.png"]
            forState:UIControlStateNormal];
    else
        [favoriteButton setImage:[UIImage imageNamed:@"NotFavorite.png"]
            forState:UIControlStateNormal];
}

- (void)setUsersTweet:(BOOL)usersTweetValue
{
    usersTweet = usersTweetValue;
}

- (void)setupWebView
{
    NSString * footerFormatString =
        NSLocalizedString(@"tweetdetailsview.tweetfooter", @"");
    NSString * dateDesc =
        [self.selectedTweet.timestamp shortDateAndTimeDescription];
    NSString * footer = self.selectedTweet.source ?
        [NSString stringWithFormat:footerFormatString,
        dateDesc ? dateDesc : @"", self.selectedTweet.source] :
        dateDesc;
    NSString * replyToString =
        NSLocalizedString(@"tweetdetailsview.replyto", @"");
    NSString * replyToLink =
        [NSString stringWithFormat:@"<a href=\"#%@\">%@ @%@</a>",
        self.selectedTweet.inReplyToTwitterTweetId, replyToString,
        self.selectedTweet.inReplyToTwitterUsername];
    footer =
        self.selectedTweet.inReplyToTwitterTweetId &&
        ![self.selectedTweet.inReplyToTwitterTweetId isEqual:@""] ?
        [NSString stringWithFormat:@"%@ %@", footer, replyToLink] :
        footer;

    NSString * body = [[self class] bodyWithUserLinks:self.selectedTweet.text];
    if (self.selectedTweet.recipient) {
        NSString * headerFormatString =
            NSLocalizedString(@"tweetdetailsview.tweetheader", @"");
        NSString * header = [NSString stringWithFormat:headerFormatString,
            self.selectedTweet.recipient.name];
        [webView
            loadHTMLStringRelativeToMainBundle:
            [[self class] htmlForContent:body footer:footer
            header:header]];
    } else
        [webView
            loadHTMLStringRelativeToMainBundle:
            [[self class] htmlForContent:body footer:footer]];
}

- (IBAction)showLocationOnMap:(id)sender
{
    [delegate showLocationOnMap:selectedTweet.user.location];
}

- (IBAction)showUserTweets:(id)sender
{
    [delegate showTweetsForUser:selectedTweet.user.username];
}

- (IBAction)sendDirectMessage:(id)sender
{
    [delegate sendDirectMessageToUser:selectedTweet.user.username];
}

- (IBAction)toggleFavoriteValue:(id)sender
{
    favorite = !favorite;
    [delegate setFavorite:favorite];
    selectedTweet.favorited = [NSNumber numberWithBool:favorite];

    if (favorite)
        [favoriteButton setImage:[UIImage imageNamed:@"Favorite.png"]
            forState:UIControlStateNormal];
    else
        [favoriteButton setImage:[UIImage imageNamed:@"NotFavorite.png"]
            forState:UIControlStateNormal];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    UIImage * avatarImage = [UIImage imageWithData:data];
    [avatar setImage:avatarImage];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark UIWebViewDelegate implementation

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(UIWebViewNavigationType)navigationType
{
    NSString * inReplyToString;
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSString * webpage = [[request URL] absoluteString];
        if ([webpage isMatchedByRegex:usernameRegex]) {
            NSString * username =
                [[webpage stringByMatching:usernameRegex] substringFromIndex:1];
            NSLog(@"Showing tweets for user: %@", username);
            [delegate showTweetsForUser:username];
        } else if (inReplyToString = [webpage stringByMatching:@"#\\d*"]) {
            NSString * tweetId = [inReplyToString substringFromIndex:1];
            NSString * replyToUsername =
                self.selectedTweet.inReplyToTwitterUsername;
            [delegate loadNewTweetWithId:tweetId username:replyToUsername];
        } else if ([webpage isMatchedByRegex:@"^mailto:"]) {
            NSLog(@"Opening 'Mail' with url: %@", webpage);
            NSURL * url = [[NSURL alloc] initWithString:webpage];
            [[UIApplication sharedApplication] openURL:url];
        } else
            [delegate visitWebpage:webpage];
    }

    return navigationType != UIWebViewNavigationTypeLinkClicked;
}
- (IBAction)reTweet:(id)sender
{
    NSLog(@"Re-tweet button selected");
    [delegate reTweetSelected];
}

- (IBAction)deleteTweet:(id)sender
{
    NSLog(@"Delete tweet button selected");
    NSString * title = @"Not yet implemented";
    NSString * message = @"Sorry, we're in the process of implementing this feature.  Thanks for beta testing!";
    UIAlertView * alert =
        [UIAlertView simpleAlertViewWithTitle:title message:message];

    [alert show];
}

#pragma mark static helper methods

+ (NSString *)htmlForContent:(NSString *)content footer:(NSString *)footer
{
    return
        [NSString stringWithFormat:
        @"<html>"
         "  <head>"
         "   <style media=\"screen\" type=\"text/css\" rel=\"stylesheet\">"
         "     @import url(tweet-style.css);"
         "   </style>"
         "  </head>"
         "  <body>"
         "    <p>%@</p><p class=\"footer\">%@</p>"
         "  </body>"
         "</html>",
        content, footer];
}

+ (NSString *)htmlForContent:(NSString *)content footer:(NSString *)footer
    header:(NSString *)header
{
    return
        [NSString stringWithFormat:
        @"<html>"
         "  <head>"
         "   <style media=\"screen\" type=\"text/css\" rel=\"stylesheet\">"
         "     @import url(tweet-style.css);"
         "   </style>"
         "  </head>"
         "  <body>"
         "    <p class=\"header\">%@</p><p>%@</p><p class=\"footer\">%@</p>"
         "  </body>"
         "</html>",
        header, content, footer];
}

// This implementation is a bit of a hack to get around a RegexKitLite
// limitation: there's a limit to how many strings can be replaced
// If not for the bug, the implementation would be:
//     return [body stringByReplacingOccurrencesOfRegex:usernameRegex
//         withString:@"<a href=\"#$1\">$1</a>"];
+ (NSString *)bodyWithUserLinks:(NSString *)body
{
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);

    NSMutableDictionary * uniqueMentions = [NSMutableDictionary dictionary];
    NSRange currentRange = [body rangeOfRegex:usernameRegex];
    while (!NSEqualRanges(currentRange, notFoundRange)) {
        NSString * mention = [body substringWithRange:currentRange];
        [uniqueMentions setObject:mention forKey:mention];

        NSUInteger startingPosition =
            currentRange.location + currentRange.length;
        if (startingPosition < [body length]) {
            NSRange remainingRange =
                NSMakeRange(startingPosition, [body length] - startingPosition);
            currentRange =
                [body rangeOfRegex:usernameRegex inRange:remainingRange];
        } else
            currentRange = notFoundRange;
    }

    NSString * bodyWithUserLinks = [[body copy] autorelease];
    for (NSString * mention in [uniqueMentions allKeys]) {
        NSString * mentionRegex =
            [NSString stringWithFormat:@"\\B(%@)\\b", mention];
        bodyWithUserLinks =
            [bodyWithUserLinks stringByReplacingOccurrencesOfRegex:mentionRegex
            withString:@"<a href=\"#$1\">$1</a>"];
    }

    return bodyWithUserLinks;
}

@end