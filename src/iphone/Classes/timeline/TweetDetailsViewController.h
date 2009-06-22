//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TweetDetailsViewDelegate.h"

@interface TweetDetailsViewController : UIViewController
{
    NSObject<TweetDetailsViewDelegate> * delegate;

    IBOutlet UIWebView * webView;
    IBOutlet UIButton * favoriteButton;
    IBOutlet UIButton * userTweetsButton;
}

@property (nonatomic, assign) NSObject<TweetDetailsViewDelegate> * delegate;

- (void)setTweet:(Tweet *)tweet;

@end
