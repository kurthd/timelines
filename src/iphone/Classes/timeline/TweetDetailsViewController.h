//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TweetDetailsViewDelegate.h"
#import "RoundedImage.h"

@interface TweetDetailsViewController : UIViewController
{
    NSObject<TweetDetailsViewDelegate> * delegate;

    IBOutlet UIWebView * webView;
    IBOutlet UIButton * favoriteButton;
    IBOutlet UIButton * userTweetsButton;
    IBOutlet UILabel * nameLabel;
    IBOutlet UIButton * locationButton;
    IBOutlet RoundedImage * avatar;
}

@property (nonatomic, assign) NSObject<TweetDetailsViewDelegate> * delegate;

- (void)setTweet:(Tweet *)tweet;

@end
