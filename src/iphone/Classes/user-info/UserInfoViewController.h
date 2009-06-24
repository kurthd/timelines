//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedImage.h"
#import "User.h"
#import "UserInfoViewControllerDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@interface UserInfoViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    NSObject<UserInfoViewControllerDelegate> * delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIView * footerView;
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * bioLabel;
    IBOutlet UILabel * followingLabel;
    IBOutlet UIButton * followButton;
    IBOutlet UIButton * sendMessageButton;

    User * user;
}

@property (nonatomic, assign)
    NSObject<UserInfoViewControllerDelegate> * delegate;

- (void)setUser:(User *)user avatarImage:(UIImage *)avatarImage;
- (IBAction)toggleFollowing:(id)sender;
- (IBAction)sendMessage:(id)sender;

@end
