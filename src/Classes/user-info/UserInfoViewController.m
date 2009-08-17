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
    kUserInfoSectionFavorites,
    kUserInfoSectionActions
};

enum {
    kUserInfoFollowingRow,
    kUserInfoFollowersRow,
    kUserInfoNumUpdatesRow,
    kUserInfoFavoritesRow
};

enum {
    kUserInfoPublicMessage,
    kUserInfoDirectMessage,
    kUserInfoSearchForUser
};

@interface UserInfoViewController ()

- (void)layoutViews;
- (void)updateDisplayForFollwoing:(BOOL)following;
- (void)updateDisplayForProcessingFollowingRequest:(BOOL)following;
- (UITableViewCell *)getBasicCell;
- (UITableViewCell *)getLabelCell;

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
    [processingFollowingIndicator release];
    [webAddressButton release];

    [followingActivityIndicator release];
    [followingLoadingLabel release];

    [followButton release];
    [stopFollowingButton release];
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
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView 
    numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows;
    if (section == kUserInfoSectionDetails) {
        numRows = 0;
        if (user.location && ![user.location isEqual:@""])
            numRows++;
    } else if (section == kUserInfoSectionActions)
        numRows = 3;
    else if (section == kUserInfoSectionFavorites)
        numRows = 1;
    else
        numRows = 3;

    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    NSString * formatString;
    UserInfoLabelCell * userInfoLabelCell;
    switch (indexPath.section) {
        case kUserInfoSectionDetails:
            cell = [self getLabelCell];
            userInfoLabelCell = (UserInfoLabelCell *)cell;
            if (user.location && ![user.location isEqual:@""] &&
                indexPath.row == 0) {

                NSString * locationString =
                    NSLocalizedString(@"userinfoview.location", @"");
                [userInfoLabelCell setKeyText:locationString];
                [userInfoLabelCell setValueText:user.location];
            }
            break;
        case kUserInfoSectionNetwork:
            cell = [self getLabelCell];
            userInfoLabelCell = (UserInfoLabelCell *)cell;
            cell.accessoryType =
                UITableViewCellAccessoryDisclosureIndicator;

            if (indexPath.row == kUserInfoFollowersRow) {
                if ([user.followersCount
                    isEqual:[NSNumber numberWithInt:0]]) {

                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                } else {
                    cell.accessoryType =
                        UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                formatString =
                    NSLocalizedString(@"userinfoview.followers", @"");
                [userInfoLabelCell setKeyText:formatString];
                [userInfoLabelCell
                    setValueText:[user.followersCount description]];
            } else if (indexPath.row == kUserInfoFollowingRow) {
                if ([user.friendsCount
                    isEqual:[NSNumber numberWithInt:0]]) {

                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                } else {
                    cell.accessoryType =
                        UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                formatString =
                    NSLocalizedString(@"userinfoview.following", @"");
                [userInfoLabelCell setKeyText:formatString];
                [userInfoLabelCell
                    setValueText:[user.friendsCount description]];
            } else {
                if ([user.statusesCount
                    isEqual:[NSNumber numberWithInt:0]]) {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle =
                        UITableViewCellSelectionStyleNone;
                } else {
                    cell.accessoryType =
                        UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle =
                        UITableViewCellSelectionStyleBlue;
                }
                formatString =
                    NSLocalizedString(@"userinfoview.statusescount", @"");
                [userInfoLabelCell setKeyText:formatString];
                [userInfoLabelCell
                    setValueText:[user.statusesCount description]];
            }
            break;
        case kUserInfoSectionFavorites:
            cell = [self getBasicCell];
            cell.accessoryType =
                UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text =
                NSLocalizedString(@"userinfoview.favorites", @"");
            cell.imageView.image =
                [UIImage imageNamed:@"FavoriteIconForUserView.png"];
            cell.imageView.highlightedImage =
                [UIImage
                imageNamed:@"FavoriteIconForUserViewHighlighted.png"];
            break;
        case kUserInfoSectionActions:
            cell = cell = [self getBasicCell];

            if (indexPath.row == kUserInfoSearchForUser) {
                cell.accessoryType =
                    UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text =
                    NSLocalizedString(@"userinfoview.searchforuser",
                    @"");
                cell.imageView.image =
                    [UIImage imageNamed:@"MagnifyingGlass.png"];
                cell.imageView.highlightedImage =
                    [UIImage
                    imageNamed:@"MagnifyingGlassHighlighted.png"];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.text =
                    indexPath.row == kUserInfoPublicMessage ?
                    NSLocalizedString(@"userinfo.publicmessage", @"") :
                    NSLocalizedString(@"userinfo.directmessage", @"");
                cell.imageView.image =
                    indexPath.row == kUserInfoPublicMessage ?
                    [UIImage imageNamed:@"PublicReplyButtonIcon.png"] :
                    [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
                cell.imageView.highlightedImage =
                    indexPath.row == kUserInfoPublicMessage ?
                    [UIImage
                    imageNamed:@"PublicReplyButtonIconHighlighted.png"] :
                    [UIImage imageNamed:@"Envelope.png"];
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
            [delegate showLocationOnMap:user.location];
            break;
        case kUserInfoSectionNetwork:
            if (indexPath.row == kUserInfoFollowingRow)
                [delegate displayFollowingForUser:user.username];
            else if (indexPath.row == kUserInfoNumUpdatesRow)
                [delegate showTweetsForUser:user.username];
            else
                [delegate displayFollowersForUser:user.username];
            break;
        case kUserInfoSectionFavorites:
            [delegate displayFavoritesForUser:user.username];
            break;
        case kUserInfoSectionActions:
            if (indexPath.row == kUserInfoPublicMessage)
                [delegate sendPublicMessageToUser:user.username];
            else if (indexPath.row == kUserInfoDirectMessage)
                [delegate sendDirectMessageToUser:user.username];
            else
                [delegate
                    showResultsForSearch:
                    [NSString stringWithFormat:@"@%@", user.username]];
            break;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kUserInfoFollowingRow &&
        indexPath.section == kUserInfoSectionNetwork &&
        [user.friendsCount isEqual:[NSNumber numberWithInt:0]])
        return nil;
    if (indexPath.row == kUserInfoFollowersRow &&
        indexPath.section == kUserInfoSectionNetwork &&
        [user.followersCount isEqual:[NSNumber numberWithInt:0]])
        return nil;
    if (indexPath.row == kUserInfoNumUpdatesRow &&
        indexPath.section == kUserInfoSectionNetwork &&
        [user.statusesCount isEqual:[NSNumber numberWithInt:0]])
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
            followingActivityIndicator.hidden = NO;
            followingLoadingLabel.hidden = NO;
            followButton.hidden = YES;
            stopFollowingButton.hidden = YES;
        } else {
            NSLog(@"Not updating following elements in header");
            [self updateDisplayForFollwoing:currentlyFollowing];
        }
    } else {
        followingActivityIndicator.hidden = YES;
        followingLoadingLabel.hidden = YES;
        activeAcctLabel.hidden = NO;
        followButton.hidden = YES;
        stopFollowingButton.hidden = YES;
    }
    activeAcctLabel.hidden = followingEnabled;

    NSString * largeAvatarUrlAsString =
        [User largeAvatarUrlForUrl:user.avatar.thumbnailImageUrl];

    UIImage * avatar = [User avatarForUrl:largeAvatarUrlAsString];
    if (!avatar)
        avatar = [User avatarForUrl:user.avatar.thumbnailImageUrl];
    if (!avatar)
        avatar = [[self class] defaultAvatar];

    [avatarView setImage:avatar];

    NSURL * largeAvatarUrl =
        [NSURL URLWithString:
        [User largeAvatarUrlForUrl:largeAvatarUrlAsString]];
    NSURL * avatarUrl =
        [NSURL URLWithString:
        [User largeAvatarUrlForUrl:user.avatar.thumbnailImageUrl]];
    [AsynchronousNetworkFetcher fetcherWithUrl:largeAvatarUrl delegate:self];
    [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];

    UIImage * avatarImage =
        [User avatarForUrl:user.avatar.thumbnailImageUrl];
    if (avatarImage)
        [avatarView setImage:avatarImage];

    nameLabel.text = aUser.name;
    bioLabel.text = [aUser.bio stringByDecodingHtmlEntities];
    
    if (user.webpage) {
        [webAddressButton setTitle:user.webpage forState:UIControlStateNormal];
        [webAddressButton setTitle:user.webpage
            forState:UIControlStateHighlighted];
    }

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
        followingActivityIndicator.hidden = YES;
        followingLoadingLabel.hidden = YES;
        followButton.hidden = YES;
        stopFollowingButton.hidden = YES;
    }
}

- (void)layoutViews
{
    CGRect bioLabelFrame = bioLabel.frame;
    bioLabelFrame.size.height = [bioLabel heightForString:bioLabel.text];
    bioLabel.frame = bioLabelFrame;

    webAddressButton.hidden = !user.webpage;
    CGRect webAddressFrame = webAddressButton.frame;
    webAddressFrame.origin.y =
        bioLabel.text.length > 0 ?
        bioLabelFrame.size.height + 388.0 : 388.0;
    webAddressButton.frame = webAddressFrame;

    CGRect headerViewFrame = headerView.frame;
    headerViewFrame.size.height =
        user.webpage ? webAddressFrame.origin.y + 24 : webAddressFrame.origin.y;
    headerView.frame = headerViewFrame;

    // force the header view to redraw
    self.tableView.tableHeaderView = headerView;
}

- (IBAction)follow:(id)sender
{
    [delegate startFollowingUser:user.username];
    [self updateDisplayForProcessingFollowingRequest:YES];
}

- (IBAction)stopFollowing:(id)sender
{
    [delegate stopFollowingUser:user.username];
    [self updateDisplayForProcessingFollowingRequest:NO];
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

    followingActivityIndicator.hidden = YES;
    followingLoadingLabel.hidden = YES;
    followButton.enabled = !following;
    stopFollowingButton.enabled = following;
    followButton.hidden = following;
    stopFollowingButton.hidden = !following;
    [processingFollowingIndicator stopAnimating];
}

- (void)updateDisplayForProcessingFollowingRequest:(BOOL)following
{
    followButton.hidden = !following;
    followButton.enabled = NO;
    stopFollowingButton.hidden = following;
    stopFollowingButton.enabled = NO;
    
    CGRect indicatorFrame = processingFollowingIndicator.frame;
    indicatorFrame.origin.x = following ? 168 : 221;
    processingFollowingIndicator.frame = indicatorFrame;
    [processingFollowingIndicator startAnimating];
}

- (IBAction)showFullProfileImage:(id)sender
{
    NSLog(@"Profile image selected");

    NSString * url = user.avatar.fullImageUrl;
    UIImage * avatarImage = [UIImage imageWithData:user.avatar.fullImage];

    RemotePhoto * remotePhoto =
        [[RemotePhoto alloc]
        initWithImage:avatarImage url:url name:user.name];
    [[PhotoBrowserDisplayMgr instance] showPhotoInBrowser:remotePhoto];
}

- (IBAction)visitWebpage:(id)sender
{
    [[TwitchWebBrowserDisplayMgr instance] visitWebpage:user.webpage];
}

- (UITableViewCell *)getBasicCell
{
    static NSString * cellIdentifier = @"UITableViewCell";

    UITableViewCell * cell =
        [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell)
        cell =
            [[[UITableViewCell alloc]
            initWithFrame:CGRectZero reuseIdentifier:cellIdentifier]
            autorelease];

    return cell;
}

- (UITableViewCell *)getLabelCell
{
    static NSString * cellIdentifier = @"UserInfoLabelCell";

    UITableViewCell * cell =
        [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        NSArray * nib =
            [[NSBundle mainBundle]
            loadNibNamed:cellIdentifier owner:self options:nil];

        cell = [nib objectAtIndex:0];
    }

    return cell;
}

+ (UIImage *)defaultAvatar
{
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar .png"] retain];

    return defaultAvatar;
}

@end
