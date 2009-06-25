//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TweetDetailsViewDelegate.h"
#import "RoundedImage.h"
#import "TweetInfo.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@interface TweetDetailsViewController :
    UIViewController <AsynchronousNetworkFetcherDelegate>
{
    NSObject<TweetDetailsViewDelegate> * delegate;

    IBOutlet UIWebView * webView;
    IBOutlet UIButton * favoriteButton;
    IBOutlet UIButton * userTweetsButton;
    IBOutlet UILabel * nameLabel;
    IBOutlet UIButton * locationButton;
    IBOutlet RoundedImage * avatar;
    
    TweetInfo * selectedTweet;
    BOOL favorite;
}

@property (nonatomic, assign) NSObject<TweetDetailsViewDelegate> * delegate;
@property (nonatomic, retain) TweetInfo * selectedTweet;

- (void)setTweet:(TweetInfo *)tweet avatar:(UIImage *)avatar;
- (IBAction)showLocationOnMap:(id)sender;
- (IBAction)showUserTweets:(id)sender;
- (IBAction)toggleFavoriteValue:(id)sender;

@end
