//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetDetailsViewController.h"
#import "Tweet.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "NSDate+StringHelpers.h"
#import "AsynchronousNetworkFetcher.h"

@interface TweetDetailsViewController ()

+ (NSString *)htmlForContent:(NSString *)content footer:(NSString *)footer;

@end

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

- (void)setTweet:(TweetInfo *)tweet avatar:(UIImage *)avatarImage
{
    self.selectedTweet = tweet;

    NSString * footerFormatString =
        NSLocalizedString(@"tweetdetailsview.tweetfooter", @"");
    NSString * dateDesc = [tweet.timestamp shortDateAndTimeDescription];
    NSString * footer =
        [NSString stringWithFormat:footerFormatString, dateDesc, tweet.source];
    [webView
        loadHTMLStringRelativeToMainBundle:
        [[self class] htmlForContent:tweet.text footer:footer]];
    nameLabel.text = tweet.user.name;
    [userTweetsButton
        setTitle:[NSString stringWithFormat:@"@%@", tweet.user.username]
        forState:UIControlStateNormal];

    if (!avatarImage) {
        NSURL * avatarUrl = [NSURL URLWithString:tweet.user.profileImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
    } else
        avatar.imageView.image = avatarImage;

    NSString * locationText = tweet.user.location;
    locationButton.hidden = !locationText || [locationText isEqual:@""];

    [locationButton setTitle:locationText forState:UIControlStateNormal];
}

- (IBAction)showLocationOnMap:(id)sender
{
    [delegate showLocationOnMap];
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

@end
