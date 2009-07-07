//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TweetDetailsViewDelegate.h"
#import "RoundedImage.h"
#import "TweetInfo.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@interface TweetDetailsViewController :
    UIViewController <AsynchronousNetworkFetcherDelegate, UIWebViewDelegate>
{
    NSObject<TweetDetailsViewDelegate> * delegate;

    IBOutlet UIWebView * webView;
    IBOutlet UIButton * favoriteButton;
    IBOutlet UIButton * userTweetsButton;
    IBOutlet UILabel * nameLabel;
    IBOutlet UIButton * locationButton;
    IBOutlet RoundedImage * avatar;
    IBOutlet UIButton * deleteTweetButton;

    TweetInfo * selectedTweet;
    BOOL favorite;

    // Required because setting directly on deleteTweetButton fails if called
    // before it's wired from loading the nib
    BOOL deleteTweetButtonEnabled;
}

@property (nonatomic, assign) NSObject<TweetDetailsViewDelegate> * delegate;
@property (nonatomic, retain) TweetInfo * selectedTweet;

- (void)setTweet:(TweetInfo *)tweet avatar:(UIImage *)avatar;
- (void)setDeleteButtonEnabled:(BOOL)enabled;

- (IBAction)showLocationOnMap:(id)sender;
- (IBAction)showUserTweets:(id)sender;
- (IBAction)toggleFavoriteValue:(id)sender;

- (IBAction)reTweet:(id)sender;
- (IBAction)deleteTweet:(id)sender;

@end
