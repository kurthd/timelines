//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TweetTextTableViewCell.h"
#import "UIWebView+FileLoadingAdditions.h"

static const CGFloat TEXT_WIDTH = 240.0;

@implementation TweetTextTableViewCell

@synthesize tweetText, webView;

- (void)dealloc
{
    self.tweetText = nil;
    [webView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGRect frame = CGRectMake(5, 0, 290, 1);
        webView = [[UIWebView alloc] initWithFrame:frame];
        webView.backgroundColor = [UIColor clearColor];
        webView.opaque = NO;
        webView.dataDetectorTypes = UIDataDetectorTypeAll;
        [self.contentView addSubview:webView];

        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

#pragma mark Accessors

- (void)setTweetText:(NSString *)someText
{
    if (someText != tweetText && ![someText isEqualToString:tweetText]) {
        [tweetText release];
        tweetText = [someText copy];

        [webView loadHTMLStringRelativeToMainBundle:tweetText];
    }
}

@end

