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
}

- (void)setTweet:(TweetInfo *)tweet avatar:(UIImage *)avatarImage
{
    self.selectedTweet = tweet;

    NSString * footerFormatString =
        NSLocalizedString(@"tweetdetailsview.tweetfooter", @"");
    NSString * dateDesc = [tweet.timestamp shortDateAndTimeDescription];
    NSString * footer = tweet.source ?
        [NSString stringWithFormat:footerFormatString,
        dateDesc ? dateDesc : @"", tweet.source] :
        dateDesc;
    NSString * replyToString =
        NSLocalizedString(@"tweetdetailsview.replyto", @"");
    NSString * replyToLink =
        [NSString stringWithFormat:@"<a href=\"#%@\">%@ @%@</a>",
        tweet.inReplyToTwitterTweetId, replyToString,
        tweet.inReplyToTwitterUsername];
    footer =
        tweet.inReplyToTwitterTweetId &&
        ![tweet.inReplyToTwitterTweetId isEqual:@""] ?
        [NSString stringWithFormat:@"%@ %@", footer, replyToLink] :
        footer;

    NSString * body = [[self class] bodyWithUserLinks:tweet.text];
    if (tweet.recipient) {
        NSString * headerFormatString =
            NSLocalizedString(@"tweetdetailsview.tweetheader", @"");
        NSString * header = [NSString stringWithFormat:headerFormatString,
            tweet.recipient.name];
        [webView
            loadHTMLStringRelativeToMainBundle:
            [[self class] htmlForContent:body footer:footer
            header:header]];
    } else
        [webView
            loadHTMLStringRelativeToMainBundle:
            [[self class] htmlForContent:body footer:footer]];

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
            [delegate loadNewTweetWithId:tweetId];
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
