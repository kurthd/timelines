//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetTextTableViewCell : UITableViewCell
{
    NSString * tweetText;
    UIWebView * webView;
}

@property (nonatomic, copy) NSString * tweetText;

@property (nonatomic, retain, readonly) UIWebView * webView;

@end
