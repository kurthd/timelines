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
#import "TwoLineButton.h"
#import "ContactMgr.h"
#import "ContactCacheReader.h"

@interface UserInfoViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    NSObject<UserInfoViewControllerDelegate> * delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIImageView * headerBackgroundView;
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UIView * footerView;
    IBOutlet RoundedImage * avatarView;
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * activeAcctLabel;
    IBOutlet UILabel * bioLabel;
    IBOutlet UIButton * followButton;
    IBOutlet UIButton * stopFollowingButton;
    IBOutlet TwoLineButton * blockButton;
    IBOutlet TwoLineButton * addToContactsButton;
    IBOutlet TwoLineButton * bookmarkButton;
    IBOutlet UIActivityIndicatorView * processingFollowingIndicator;
    IBOutlet UIButton * webAddressButton;
    IBOutlet UILabel * followsYouLabel;

    ContactMgr * contactMgr;
    NSObject<ContactCacheReader> * contactCacheReader;

    BOOL currentlyFollowing;
    BOOL followingEnabled;
    BOOL followingStateSet;
    BOOL blockedStateSet;
    BOOL currentlyBlocked;
    BOOL followsYouLabelSet;
    BOOL followedByUser;

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
@property (nonatomic, retain) ContactMgr * contactMgr;
@property (nonatomic, retain) NSObject<ContactCacheReader> * contactCacheReader;

- (void)setUser:(User *)user;
- (void)setFollowing:(BOOL)enabled;
- (void)setFailedToQueryFollowing;
- (void)showingNewUser;
- (IBAction)follow:(id)sender;
- (IBAction)stopFollowing:(id)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)showFullProfileImage:(id)sender;
- (IBAction)visitWebpage:(id)sender;

- (void)setQueryingFollowedBy;
- (void)setFailedToQueryFollowedBy;
- (void)setFollowedBy:(BOOL)followedBy;

- (void)setBlocked:(BOOL)blocked;
- (void)setFailedToQueryBlocked;

@end
