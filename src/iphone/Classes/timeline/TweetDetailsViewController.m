//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetDetailsViewController.h"
#import "Tweet.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "NSDate+StringHelpers.h"
#import "AsynchronousNetworkFetcher.h"
#import "RegexKitLite.h"

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
        avatar.imageView.image = [UIImage imageNamed:@"DefaultAvatar.png"];
    } else
        avatar.imageView.image = avatarImage;

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
    avatar.imageView.image = avatarImage;
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

+ (NSString *)bodyWithUserLinks:(NSString *)body
{
    return [body stringByReplacingOccurrencesOfRegex:usernameRegex
        withString:@"<a href=\"#$1\">$1</a>"];
}

@end
