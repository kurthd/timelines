//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedImage.h"
#import "User.h"
#import "UserInfoViewControllerDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "SavedSearchMgr.h"

@interface UserInfoViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    NSObject<UserInfoViewControllerDelegate> * delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIView * footerView;
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * activeAcctLabel;
    IBOutlet UILabel * bioLabel;
    IBOutlet UILabel * followingLabel;
    IBOutlet UILabel * followingCheckMark;
    IBOutlet UIActivityIndicatorView * followingActivityIndicator;
    IBOutlet UILabel * followingLoadingLabel;
    IBOutlet UIButton * followButton;
    IBOutlet UIButton * bookmarkButton;

    BOOL currentlyFollowing;
    BOOL followingEnabled;
    BOOL followingStateSet;

    User * user;

    SavedSearchMgr * findPeopleBookmarkMgr;
}

@property (nonatomic, assign)
    NSObject<UserInfoViewControllerDelegate> * delegate;
@property (nonatomic, assign) BOOL followingEnabled;
@property (nonatomic, retain) SavedSearchMgr * findPeopleBookmarkMgr;

- (void)setUser:(User *)user avatarImage:(UIImage *)avatarImage;
- (void)setUser:(User *)user;
- (void)setFollowing:(BOOL)enabled;
- (void)showingNewUser;
- (IBAction)toggleFollowing:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)bookmark:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;

@end
