//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "DirectMessageViewControllerDelegate.h"
#import "TweetInfo.h"
#import "RoundedImage.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "MarkAsFavoriteCell.h"

@interface DirectMessageViewController :
    UITableViewController <UIActionSheetDelegate, UIWebViewDelegate,
    AsynchronousNetworkFetcherDelegate, MFMailComposeViewControllerDelegate>
{
    NSObject<DirectMessageViewControllerDelegate> * delegate;

    UINavigationController * navigationController;

    IBOutlet UIView * headerView;
    IBOutlet UIView * footerView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet RoundedImage * avatarImage;

    UITableViewCell * tweetTextTableViewCell;
    UIWebView * tweetContentView;

    TweetInfo * tweet;

    UIViewController * realParentViewController;

    UITableViewCell * replyCell;
    UITableViewCell * deleteTweetCell;

    BOOL usersTweet;
}

@property (nonatomic, assign)
    NSObject<DirectMessageViewControllerDelegate> * delegate;
@property (nonatomic, retain, readonly) TweetInfo * tweet;
@property (nonatomic, retain) UIViewController * realParentViewController;

- (void)displayTweet:(TweetInfo *)tweet
    onNavigationController:(UINavigationController *)navController;
- (void)setUsersTweet:(BOOL)usersTweet;

#pragma mark Button actions

- (IBAction)showUserTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;
- (IBAction)sendInEmail;

@end
