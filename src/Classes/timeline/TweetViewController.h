//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TweetViewControllerDelegate.h"
#import "TweetInfo.h"
#import "RoundedImage.h"
#import "AsynchronousNetworkFetcherDelegate.h"

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
    UIImage * avatar;

    // configure the display
    BOOL showsFavoriteButton;
    BOOL showsExtendedActions;
}

@property (nonatomic, assign) NSObject<TweetViewControllerDelegate> * delegate;
@property (nonatomic, retain, readonly) TweetInfo * tweet;
@property (nonatomic, retain, readonly) UIImage * avatar;
@property (nonatomic, assign) BOOL showsExtendedActions;

- (void)displayTweet:(TweetInfo *)tweet avatar:(UIImage *)avatar
    onNavigationController:(UINavigationController *)navController;
- (void)setUsersTweet:(BOOL)usersTweet;
- (void)hideFavoriteButton:(BOOL)hide;

#pragma mark Button actions

- (IBAction)showUserTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

@end
