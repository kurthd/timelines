//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TweetDetailsViewDelegate.h"
#import "TweetInfo.h"
#import "RoundedImage.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@class TweetTextTableViewCell;

@interface TweetViewController :
    UITableViewController <UIActionSheetDelegate, UIWebViewDelegate,
    AsynchronousNetworkFetcherDelegate, MFMailComposeViewControllerDelegate>
{
    NSObject<TweetDetailsViewDelegate> * delegate;

    IBOutlet UIView * headerView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * locationLabel;
    IBOutlet RoundedImage * avatarImage;

    TweetTextTableViewCell * tweetTextTableViewCell;

    TweetInfo * selectedTweet;
    UIImage * avatar;
    UIWebView * tweetContentView;
}

@property (nonatomic, assign) NSObject<TweetDetailsViewDelegate> * delegate;
@property (nonatomic, retain) TweetInfo * selectedTweet;
@property (nonatomic, retain) UIImage * avatar;

- (void)displayTweet:(TweetInfo *)tweet avatar:(UIImage *)avatar
   withPreConfiguredView:(UIView *)view;
- (void)setUsersTweet:(BOOL)usersTweet;
- (void)hideFavoriteButton:(BOOL)hide;

#pragma mark Button actions

- (IBAction)showUserTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

@end
