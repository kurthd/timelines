//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TweetViewControllerDelegate.h"
#import "TweetInfo.h"
#import "RoundedImage.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "MarkAsFavoriteCell.h"

@interface TweetViewController :
    UITableViewController <UIActionSheetDelegate, UIWebViewDelegate,
    AsynchronousNetworkFetcherDelegate, MFMailComposeViewControllerDelegate>
{
    NSObject<TweetViewControllerDelegate> * delegate;

    UINavigationController * navigationController;

    IBOutlet UIView * headerView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet RoundedImage * avatarImage;

    UITableViewCell * tweetTextTableViewCell;
    UIWebView * tweetContentView;

    TweetInfo * tweet;

    // configure the display
    BOOL showsFavoriteButton;
    BOOL showsExtendedActions;

    UIViewController * realParentViewController;

    UITableViewCell * publicReplyCell;
    UITableViewCell * directMessageCell;
    UITableViewCell * retweetCell;
    MarkAsFavoriteCell * favoriteCell;

    BOOL markingFavorite;
}

@property (nonatomic, assign) NSObject<TweetViewControllerDelegate> * delegate;
@property (nonatomic, retain, readonly) TweetInfo * tweet;
@property (nonatomic, assign) BOOL showsExtendedActions;
@property (nonatomic, retain) UIViewController * realParentViewController;

- (void)displayTweet:(TweetInfo *)tweet
    onNavigationController:(UINavigationController *)navController;
- (void)setFavorited:(BOOL)favorited;
- (void)setUsersTweet:(BOOL)usersTweet;
- (void)hideFavoriteButton:(BOOL)hide;

#pragma mark Button actions

- (IBAction)showUserTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

@end
