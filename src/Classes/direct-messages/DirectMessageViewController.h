//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "DirectMessageViewControllerDelegate.h"
#import "DirectMessage.h"
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
    IBOutlet UIImageView * headerBackgroundView;
    IBOutlet UIImageView * avatarBackgroundView;
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerBottomLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UIImageView * chatArrowView;
    IBOutlet UIView * footerView;
    IBOutlet UILabel * fullNameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet RoundedImage * avatarImage;
    IBOutlet UIButton * emailButton;

    UITableViewCell * tweetTextTableViewCell;
    UIWebView * tweetContentView;

    DirectMessage * directMessage;

    UIViewController * realParentViewController;

    UITableViewCell * replyCell;
    UITableViewCell * deleteTweetCell;

    BOOL usersDirectMessage;
}

@property (nonatomic, assign)
    NSObject<DirectMessageViewControllerDelegate> * delegate;
@property (nonatomic, retain, readonly) DirectMessage * directMessage;
@property (nonatomic, retain) UIViewController * realParentViewController;

- (void)displayDirectMessage:(DirectMessage *)dm
    onNavigationController:(UINavigationController *)navController;
- (void)setUsersDirectMessage:(BOOL)usersDirectMessage;

#pragma mark Button actions

- (IBAction)showUserTweets:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;
- (IBAction)sendInEmail;

@end
