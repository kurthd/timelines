//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedImage.h"
#import "User.h"
#import "UserInfoViewControllerDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "SavedSearchMgr.h"
#import "LocationCell.h"

@interface UserInfoViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    NSObject<UserInfoViewControllerDelegate> * delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIImageView * avatarBackgroundView;
    IBOutlet UIImageView * headerBackgroundView;
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerBottomLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UIView * footerView;
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * activeAcctLabel;
    IBOutlet UILabel * bioLabel;
    IBOutlet UIButton * followButton;
    IBOutlet UIButton * stopFollowingButton;
    IBOutlet UIButton * blockButton;
    IBOutlet UIButton * bookmarkButton;
    IBOutlet UIActivityIndicatorView * processingFollowingIndicator;
    IBOutlet UIButton * webAddressButton;
    IBOutlet UILabel * followsYouLabel;

    BOOL currentlyFollowing;
    BOOL followingEnabled;
    BOOL followingStateSet;
    BOOL blockedStateSet;
    BOOL currentlyBlocked;

    User * user;

    SavedSearchMgr * findPeopleBookmarkMgr;
    LocationCell * locationCell;

    BOOL lastDisplayedInLandscape;
}

@property (nonatomic, assign)
    NSObject<UserInfoViewControllerDelegate> * delegate;
@property (nonatomic, assign) BOOL followingEnabled;
@property (nonatomic, retain) SavedSearchMgr * findPeopleBookmarkMgr;
@property (nonatomic, readonly) LocationCell * locationCell;

- (void)setUser:(User *)user;
- (void)setFollowing:(BOOL)enabled;
- (void)setFailedToQueryFollowing;
- (void)showingNewUser;
- (IBAction)follow:(id)sender;
- (IBAction)stopFollowing:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)bookmark:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;
- (IBAction)visitWebpage:(id)sender;
- (IBAction)changeBlockedState:(id)sender;

- (void)setQueryingFollowedBy;
- (void)setFailedToQueryFollowedBy;
- (void)setFollowedBy:(BOOL)followedBy;

- (void)setBlocked:(BOOL)blocked;
- (void)setFailedToQueryBlocked;

@end
