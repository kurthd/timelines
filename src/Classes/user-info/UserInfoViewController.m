//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserInfoViewController.h"
#import "UILabel+DrawingAdditions.h"
#import "UIColor+TwitchColors.h"
#import "UserInfoLabelCell.h"
#import "AsynchronousNetworkFetcher.h"
#import "NSString+HtmlEncodingAdditions.h"
#import "User+UIAdditions.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "PhotoBrowserDisplayMgr.h"

enum {
    kUserInfoSectionDetails,
    kUserInfoSectionNetwork,
    kUserInfoSectionTweets
};

enum {
    kUserInfoFollowingRow,
    kUserInfoFollowersRow
};

enum {
    kUserInfoNumUpdatesRow,
    kUserInfoFavoritesRow
};

@interface UserInfoViewController ()

- (void)layoutViews;
- (void)updateDisplayForFollwoing:(BOOL)following;

+ (UIImage *)defaultAvatar;

@end

@implementation UserInfoViewController

@synthesize delegate, followingEnabled, findPeopleBookmarkMgr;

static UIImage * defaultAvatar;

- (void)dealloc
{
    [headerView release];
    [footerView release];
    [avatarView release];
    [nameLabel release];
    [activeAcctLabel release];
    [bioLabel release];

    [followingLabel release];
    [followingCheckMark release];
    [followingActivityIndicator release];
    [followingLoadingLabel release];

    [followButton release];
    [bookmarkButton release];

    [user release];

    [findPeopleBookmarkMgr release];

    [super dealloc];
}

- (void)viewDidLoad
{
    NSLog(@"Loading new user info view controller");
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor twitchBackgroundColor];

    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = footerView;
    
    [self layoutViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [delegate showingUserInfoView];
    bookmarkButton.enabled =
        ![findPeopleBookmarkMgr isSearchSaved:user.username];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView 
    numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows;
    if (section == kUserInfoSectionDetails) {
        numRows = 0;
        if (user.location && ![user.location isEqual:@""])
            numRows++;
        if (user.webpage && ![user.webpage isEqual:@""])
            numRows++;
    } else
        numRows = 2;

    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    NSString * formatString;
    NSNumber * count;
    NSArray * nib;
    switch (indexPath.section) {
        case kUserInfoSectionDetails:
            nib =
                [[NSBundle mainBundle] loadNibNamed:@"UserInfoLabelCell"
                owner:self options:nil];

            cell = [nib objectAtIndex:0];
            UserInfoLabelCell * userInfoLabelCell = (UserInfoLabelCell *)cell;
            if (user.location && ![user.location isEqual:@""] &&
                indexPath.row == 0) {

                NSString * locationString =
                    NSLocalizedString(@"userinfoview.location", @"");
                [userInfoLabelCell setKeyText:locationString];
                [userInfoLabelCell setValueText:user.location];
            } else {
                NSString * webpageString =
                    NSLocalizedString(@"userinfoview.webpage", @"");
                [userInfoLabelCell setKeyText:webpageString];
                [userInfoLabelCell setValueText:user.webpage];
            }
            break;
        case kUserInfoSectionNetwork:
                cell =
                    [[[UITableViewCell alloc]
                    initWithFrame:CGRectZero reuseIdentifier:@"UITableViewCell"]
                    autorelease];
                cell.accessoryType =
                    UITableViewCellAccessoryDisclosureIndicator;

                if (indexPath.row == kUserInfoFollowersRow) {
                    if ([user.followersCount
                        isEqual:[NSNumber numberWithInt:0]]) {

                        cell.textLabel.textColor = [UIColor grayColor];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    } else {
                        cell.textLabel.textColor = [UIColor blackColor];
                        cell.accessoryType =
                            UITableViewCellAccessoryDisclosureIndicator;
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    }
                    formatString =
                        NSLocalizedString(@"userinfoview.followers", @"");
                    count = user.followersCount;
                } else {
                    if ([user.friendsCount
                        isEqual:[NSNumber numberWithInt:0]]) {

                        cell.textLabel.textColor = [UIColor grayColor];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    } else {
                        cell.textLabel.textColor = [UIColor blackColor];
                        cell.accessoryType =
                            UITableViewCellAccessoryDisclosureIndicator;
                        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    }
                    formatString =
                        NSLocalizedString(@"userinfoview.following", @"");
                    count = user.friendsCount;
                }

                cell.textLabel.text =
                    [NSString stringWithFormat:formatString, count];
                break;
            case kUserInfoSectionTweets:
                cell =
                    [[[UITableViewCell alloc]
                    initWithFrame:CGRectZero reuseIdentifier:@"UITableViewCell"]
                    autorelease];
                    cell.accessoryType =
                        UITableViewCellAccessoryDisclosureIndicator;

                    if (indexPath.row == kUserInfoFavoritesRow) {
                        cell.textLabel.text =
                            NSLocalizedString(@"userinfoview.favorites", @"");
                        cell.imageView.image =
                            [UIImage imageNamed:@"FavoriteIconForUserView.png"];
                        cell.imageView.highlightedImage =
                            [UIImage
                            imageNamed:
                            @"FavoriteIconForUserViewHighlighted.png"];
                    } else {
                        if ([user.statusesCount
                            isEqual:[NSNumber numberWithInt:0]]) {
                            cell.textLabel.textColor = [UIColor grayColor];
                            cell.accessoryType = UITableViewCellAccessoryNone;
                            cell.selectionStyle =
                                UITableViewCellSelectionStyleNone;
                        } else {
                            cell.textLabel.textColor = [UIColor blackColor];
                            cell.accessoryType =
                                UITableViewCellAccessoryDisclosureIndicator;
                            cell.selectionStyle =
                                UITableViewCellSelectionStyleBlue;
                        }
                        cell.textLabel.text =
                            [NSString stringWithFormat:
                            NSLocalizedString(
                            @"userinfoview.statusescount.formatstring", @""),
                            user.statusesCount];
                    }
                break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kUserInfoSectionDetails:
            if (user.location && ![user.location isEqual:@""] &&
                indexPath.row == 0)
                [delegate showLocationOnMap:user.location];
            else
                [[TwitchWebBrowserDisplayMgr instance] visitWebpage:user.webpage];
            break;
        case kUserInfoSectionNetwork:
            if (indexPath.row == kUserInfoFollowingRow)
                [delegate displayFollowingForUser:user.username];
            else
                [delegate displayFollowersForUser:user.username];
            break;
        case kUserInfoSectionTweets:
            if (indexPath.row == kUserInfoFavoritesRow)
                [delegate displayFavoritesForUser:user.username];
            else
                [delegate showTweetsForUser:user.username];
            break;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kUserInfoFollowingRow &&
        [user.friendsCount isEqual:[NSNumber numberWithInt:0]])
        return nil;
    if (indexPath.row == kUserInfoFollowersRow &&
        [user.followersCount isEqual:[NSNumber numberWithInt:0]])
        return nil;

    return indexPath;
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    UIImage * avatarImage = [UIImage imageWithData:data];
    NSString * urlAsString = [url absoluteString];
    [User setAvatar:avatarImage forUrl:urlAsString];
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);
    if (NSEqualRanges([urlAsString rangeOfString:@"_normal."], notFoundRange) &&
        avatarImage)
        [avatarView setImage:avatarImage];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark UserInfoViewController implementation

- (void)setUser:(User *)aUser
{
    [aUser retain];
    [user release];
    user = aUser;

    if (followingEnabled) {
        if (!followingStateSet) {
            followingLabel.hidden = YES;
            followingCheckMark.hidden = YES;
            followingActivityIndicator.hidden = NO;
            followingLoadingLabel.hidden = NO;
        } else {
            NSLog(@"Not updating following elements in header");
            [self updateDisplayForFollwoing:currentlyFollowing];
        }

        [followButton setTitleColor:[UIColor grayColor]
            forState:UIControlStateNormal];
        NSString * startFollowingText =
            NSLocalizedString(@"userinfoview.startfollowing", @"");
        [followButton setTitle:startFollowingText
            forState:UIControlStateNormal];
    } else {
        followingLabel.hidden = YES;
        followingCheckMark.hidden = YES;
        followingActivityIndicator.hidden = YES;
        followingLoadingLabel.hidden = YES;
        activeAcctLabel.hidden = NO;
        [followButton setTitleColor:[UIColor grayColor]
            forState:UIControlStateNormal];
        NSString * followingBtnText =
            NSLocalizedString(@"userinfoview.startfollowing", @"");
        [followButton setTitle:followingBtnText forState:UIControlStateNormal];
    }
    activeAcctLabel.hidden = followingEnabled;

    NSString * largeAvatarUrlAsString =
        [User largeAvatarUrlForUrl:user.profileImageUrl];

    UIImage * avatar = [User avatarForUrl:largeAvatarUrlAsString];
    if (!avatar)
        avatar = [User avatarForUrl:user.profileImageUrl];
    if (!avatar)
        avatar = [[self class] defaultAvatar];

    [avatarView setImage:avatar];

    NSURL * largeAvatarUrl =
        [NSURL URLWithString:
        [User largeAvatarUrlForUrl:largeAvatarUrlAsString]];
    NSURL * avatarUrl =
        [NSURL URLWithString:[User largeAvatarUrlForUrl:user.profileImageUrl]];
    [AsynchronousNetworkFetcher fetcherWithUrl:largeAvatarUrl delegate:self];
    [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];

    UIImage * avatarImage = [User avatarForUrl:user.profileImageUrl];
    if (avatarImage)
        [avatarView setImage:avatarImage];

    nameLabel.text = aUser.name;
    bioLabel.text = [aUser.bio stringByDecodingHtmlEntities];

    [self layoutViews];
    [self.tableView reloadData];
}

- (void)showingNewUser
{
    followingStateSet = NO;
}

- (void)setFollowing:(BOOL)following
{
    followingStateSet = YES;
    currentlyFollowing = following;

    if (followingEnabled)
        [self updateDisplayForFollwoing:following];
    else {
        followingLabel.hidden = YES;
        followingCheckMark.hidden = YES;
        followingActivityIndicator.hidden = YES;
        followingLoadingLabel.hidden = YES;
        followButton.enabled = NO;
        [followButton setTitleColor:[UIColor grayColor]
            forState:UIControlStateNormal];
        NSString * followingBtnText =
            NSLocalizedString(@"userinfoview.startfollowing", @"");
        [followButton setTitle:followingBtnText forState:UIControlStateNormal];
    }
}

- (void)layoutViews
{
    CGRect bioLabelFrame = bioLabel.frame;
    bioLabelFrame.size.height = [bioLabel heightForString:bioLabel.text];
    bioLabel.frame = bioLabelFrame;

    CGRect headerViewFrame = headerView.frame;
    headerViewFrame.size.height =
        bioLabel.text.length > 0 ?
        bioLabelFrame.size.height + 390.0 : 376.0;
    headerView.frame = headerViewFrame;

    // force the header view to redraw
    self.tableView.tableHeaderView = headerView;
}

- (IBAction)toggleFollowing:(id)sender
{
    NSLog(@"Toggling following state");
    currentlyFollowing = !currentlyFollowing;
    if (currentlyFollowing)
        [delegate startFollowingUser:user.username];
    else
        [delegate stopFollowingUser:user.username];
    [self updateDisplayForFollwoing:currentlyFollowing];
}

- (IBAction)sendMessage:(id)sender
{
    NSLog(@"'Send message' selected");
    [delegate sendDirectMessageToUser:user.username];
}

- (IBAction)bookmark:(id)sender
{
    NSLog(@"Bookmarking user");
    [findPeopleBookmarkMgr addSavedSearch:user.username];
    bookmarkButton.enabled = NO;
}

- (void)updateDisplayForFollwoing:(BOOL)following
{
    NSLog(@"User info view: updating display for following");
    if (following)
        NSLog(@"Following");
    else
        NSLog(@"Not following");

    followingLabel.hidden = NO;
    followingLabel.text =
        following ?
        NSLocalizedString(@"userinfoview.followinglabel.following", @"") :
        NSLocalizedString(@"userinfoview.followinglabel.notfollowing", @"");
    followingCheckMark.hidden = !following;
    followingActivityIndicator.hidden = YES;
    followingLoadingLabel.hidden = YES;
    followButton.enabled = YES;
    [followButton setTitleColor:[UIColor twitchCheckedColor]
        forState:UIControlStateNormal];
    NSString * followingBtnText =
        following ?
        NSLocalizedString(@"userinfoview.stopfollowing", @"") :
        NSLocalizedString(@"userinfoview.startfollowing", @"");
    [followButton setTitle:followingBtnText forState:UIControlStateNormal];
}

- (IBAction)showFullProfileImage:(id)sender
{
    NSLog(@"Profile image selected");

    NSString * url =
        [user.profileImageUrl
        stringByReplacingOccurrencesOfString:@"_normal."
        withString:@"."];
    UIImage * avatarImage =
        [url isEqualToString:user.profileImageUrl] ?
        (avatarView.image != [[self class] defaultAvatar] ?
        avatarView.image : nil) :
        nil;

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:avatarImage url:url name:user.name];
    [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
}

+ (UIImage *)defaultAvatar
{
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar .png"] retain];

    return defaultAvatar;
}

@end
