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
    
    Tweet * selectedTweet;
}

@property (nonatomic, assign) NSObject<TweetDetailsViewDelegate> * delegate;
@property (nonatomic, retain) Tweet * selectedTweet;

- (void)setTweet:(Tweet *)tweet;
- (IBAction)showLocationOnMap:(id)sender;

@end
