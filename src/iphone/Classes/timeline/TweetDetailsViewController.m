//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetDetailsViewController.h"
#import "Tweet.h"
#import "UIWebView+FileLoadingAdditions.h"

@interface TweetDetailsViewController ()

+ (NSString *)htmlForContent:(NSString *)content;

@end

@implementation TweetDetailsViewController

@synthesize delegate;

- (void)dealloc
{
    [webView release];
    [favoriteButton release];
    [userTweetsButton release];
    [super dealloc];
}

- (void)setTweet:(Tweet *)tweet
{
    [webView
        loadHTMLStringRelativeToMainBundle:
        [[self class] htmlForContent:tweet.text]];
}

+ (NSString *)htmlForContent:(NSString *)content
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
         "    %@"
         "  </body>"
         "</html>",
        content];
}

@end
