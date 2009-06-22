//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetDetailsViewController.h"
#import "Tweet.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "NSDate+StringHelpers.h"

@interface TweetDetailsViewController ()

+ (NSString *)htmlForContent:(NSString *)content footer:(NSString *)footer;

@end

@implementation TweetDetailsViewController

@synthesize delegate;

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

- (void)setTweet:(Tweet *)tweet
{
    NSString * footerFormatString =
        NSLocalizedString(@"tweetdetailsview.tweetfooter", @"");
    NSString * dateDesc = [tweet.timestamp shortDateAndTimeDescription];
    NSString * footer =
        [NSString stringWithFormat:footerFormatString, dateDesc, tweet.source];
    [webView
        loadHTMLStringRelativeToMainBundle:
        [[self class] htmlForContent:tweet.text footer:footer]];
    nameLabel.text = tweet.user.name;
    [userTweetsButton setTitle:tweet.user.username
        forState:UIControlStateNormal];
    NSURL * avatarUrl = [NSURL URLWithString:tweet.user.profileImageUrl];
    NSData * avatarData = [NSData dataWithContentsOfURL:avatarUrl];
    avatar.imageView.image = [UIImage imageWithData:avatarData];
    
    NSString * locationText = tweet.user.location;
    locationButton.hidden = !locationText || [locationText isEqual:@""];

    [locationButton setTitle:locationText forState:UIControlStateNormal];
}

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
