//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TweetDetailsViewDelegate.h"
#import "TweetInfo.h"
#import "RoundedImage.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "UIWebView+FileLoadingAdditions.h"

@class TweetTextTableViewCell;

@interface TweetViewController :
    UITableViewController <UIActionSheetDelegate, UIWebViewDelegate,
    AsynchronousNetworkFetcherDelegate, MFMailComposeViewControllerDelegate>
{
    NSObject<TweetDetailsViewDelegate> * delegate;

    UINavigationController * navigationController;

    IBOutlet UIView * headerView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet RoundedImage * avatarImage;

    UITableViewCell * tweetTextTableViewCell;
    UIWebView * tweetContentView;
    //TweetTextTableViewCell * tweetTextTableViewCell;

    TweetInfo * tweet;
    UIImage * avatar;
}

@property (nonatomic, assign) NSObject<TweetDetailsViewDelegate> * delegate;
@property (nonatomic, retain, readonly) TweetInfo * tweet;
@property (nonatomic, retain, readonly) UIImage * avatar;

- (void)displayTweet:(TweetInfo *)tweet avatar:(UIImage *)avatar
    onNavigationController:(UINavigationController *)navController;
//- (void)displayTweet:(TweetInfo *)tweet avatar:(UIImage *)avatar
//    withPreLoadedView:(UIView *)view;
- (void)setUsersTweet:(BOOL)usersTweet;
- (void)hideFavoriteButton:(BOOL)hide;

#pragma mark Button actions

- (IBAction)showUserTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

@end
