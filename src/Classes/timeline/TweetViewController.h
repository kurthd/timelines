//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TweetViewControllerDelegate.h"
#import "Tweet.h"
#import "RoundedImage.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "MarkAsFavoriteCell.h"
#import "TweetLocationCell.h"
#import "ActionButtonCell.h"

@interface TweetViewController :
    UITableViewController <UIActionSheetDelegate, UIWebViewDelegate,
    AsynchronousNetworkFetcherDelegate, MFMailComposeViewControllerDelegate>
{
    NSObject<TweetViewControllerDelegate> * delegate;

    UINavigationController * navigationController;

    IBOutlet UIView * headerView;
    IBOutlet UIImageView * headerBackgroundView;
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UIImageView * chatArrowView;
    IBOutlet UIView * footerView;
    IBOutlet UIButton * openInBrowserButton;
    IBOutlet UIButton * emailButton;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet RoundedImage * avatarImage;

    UITableViewCell * tweetTextTableViewCell;
    UITableViewCell * conversationCell;
    UIWebView * tweetContentView;

    Tweet * tweet;

    // configure the display
    BOOL showsFavoriteButton;
    BOOL showsExtendedActions;
    BOOL allowDeletion;

    UIViewController * realParentViewController;

    TweetLocationCell * locationCell;
    ActionButtonCell * publicReplyCell;
    ActionButtonCell * retweetCell;
    MarkAsFavoriteCell * favoriteCell;
    ActionButtonCell * deleteTweetCell;
        
    BOOL markingFavorite;

    BOOL lastDisplayedInLandscape;
}

@property (nonatomic, assign) NSObject<TweetViewControllerDelegate> * delegate;
@property (nonatomic, retain, readonly) Tweet * tweet;
@property (nonatomic, assign) BOOL showsExtendedActions;
@property (nonatomic, assign) BOOL allowDeletion;
@property (nonatomic, retain) UIViewController * realParentViewController;
@property (nonatomic, readonly) TweetLocationCell * locationCell;

- (void)displayTweet:(Tweet *)tweet
    onNavigationController:(UINavigationController *)navController;
- (void)setFavorited:(BOOL)favorited;
- (void)setUsersTweet:(BOOL)usersTweet;
- (void)hideFavoriteButton:(BOOL)hide;

#pragma mark Button actions

- (IBAction)showUserTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;
- (IBAction)openTweetInBrowser;
- (IBAction)sendInEmail;

@end
