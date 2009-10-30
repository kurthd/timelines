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
#import "RotatableTabBarController.h"
#import "SettingsReader.h"
#import "TimelineTableViewCellView.h"

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
- (void)updateButtonsForOrientation:(UIInterfaceOrientation)o;
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
    [avatarBackgroundView release];
    [headerBackgroundView release];
    [headerTopLine release];
    [headerBottomLine release];
    [headerViewPadding release];
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
    [blockButton release];
    [bookmarkButton release];

    [user release];

    [findPeopleBookmarkMgr release];
    [locationCell release];

    [super dealloc];
}

- (void)viewDidLoad
{
    NSLog(@"Loading new user info view controller");
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor twitchBackgroundColor];

    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = footerView;
    
    self.view.frame =
        [[RotatableTabBarController instance] landscape] ?
        CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);
    
    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        self.tableView.separatorColor = [UIColor twitchGrayColor];

        headerBackgroundView.image =
            [UIImage imageNamed:@"UserHeaderDarkThemeGradient.png"];
        avatarBackgroundView.image =
            [UIImage imageNamed:@"AvatarDarkThemeBackground.png"];
        headerTopLine.backgroundColor = [UIColor blackColor];
        headerBottomLine.backgroundColor = [UIColor twitchGrayColor];
        headerViewPadding.backgroundColor =
            [TimelineTableViewCellView defaultDarkThemeCellColor];

        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.shadowColor = [UIColor blackColor];

        followingLoadingLabel.shadowColor =
            [UIColor colorWithRed:.1 green:.1 blue:.1 alpha:1];

        [stopFollowingButton
            setBackgroundImage:
            [UIImage imageNamed:@"StopFollowingButtonDarkTheme.png"]
            forState:UIControlStateNormal];
        [stopFollowingButton
            setBackgroundImage:
            [UIImage imageNamed:@"StopFollowingButtonDarkThemeHighlighted.png"]
            forState:UIControlStateHighlighted];
        [stopFollowingButton
            setTitleShadowColor:
            [UIColor colorWithRed:.1 green:.1 blue:.1 alpha:1]
            forState:UIControlStateNormal];
        [stopFollowingButton setTitleColor:[UIColor lightGrayColor]
            forState:UIControlStateNormal];

        [followButton
            setBackgroundImage:
            [UIImage imageNamed:@"FollowButtonDarkTheme.png"]
            forState:UIControlStateNormal];
        [followButton
            setBackgroundImage:
            [UIImage imageNamed:@"FollowButtonDarkThemeHighlighted.png"]
            forState:UIControlStateHighlighted];
        [followButton
            setTitleShadowColor:
            [UIColor colorWithRed:.1 green:.1 blue:.1 alpha:1]
            forState:UIControlStateNormal];
        [followButton setTitleColor:[UIColor lightGrayColor]
            forState:UIControlStateNormal];

        self.view.backgroundColor =
            [UIColor colorWithPatternImage:
            [UIImage imageNamed:@"DarkThemeBackground.png"]];

        bioLabel.textColor = [UIColor lightGrayColor];
        bioLabel.shadowColor = [UIColor blackColor];

        [webAddressButton
            setTitleColor:[UIColor twitchBlueOnDarkBackgroundColor]
            forState:UIControlStateNormal];
        [webAddressButton setTitleShadowColor:[UIColor blackColor]
            forState:UIControlStateNormal];

        UIImage * buttonImage =
            [[UIImage imageNamed:@"DarkThemeButtonBackground.png"]
            stretchableImageWithLeftCapWidth:10 topCapHeight:0];

        [blockButton setBackgroundImage:buttonImage
            forState:UIControlStateNormal];
        [blockButton setTitleColor:[UIColor twitchBlueOnDarkBackgroundColor]
            forState:UIControlStateNormal];
        [blockButton setTitleColor:[UIColor darkGrayColor]
            forState:UIControlStateDisabled];
        [blockButton setBackgroundImage:buttonImage
            forState:UIControlStateDisabled];

        [bookmarkButton setBackgroundImage:buttonImage
            forState:UIControlStateNormal];
        [bookmarkButton setTitleColor:[UIColor twitchBlueOnDarkBackgroundColor]
            forState:UIControlStateNormal];
        [bookmarkButton setTitleColor:[UIColor darkGrayColor]
            forState:UIControlStateDisabled];
        [bookmarkButton setBackgroundImage:buttonImage
            forState:UIControlStateDisabled];
            
        activeAcctLabel.shadowColor = [UIColor blackColor];
    }

    [self layoutViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.frame =
        [[RotatableTabBarController instance] landscape] ?
        CGRectMake(0, 0, 480, 220) : CGRectMake(0, 0, 320, 367);

    [delegate showingUserInfoView];
    UIInterfaceOrientation orientation =
        [[RotatableTabBarController instance] effectiveOrientation];
    [self updateButtonsForOrientation:orientation];
    
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    if (lastDisplayedInLandscape != landscape) {
        [self.tableView reloadData];
        [self layoutViews];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    lastDisplayedInLandscape = [[RotatableTabBarController instance] landscape];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self updateButtonsForOrientation:o];
    [self.tableView reloadData];
    [self layoutViews];
}

- (void)updateButtonsForOrientation:(UIInterfaceOrientation)o
{
    CGFloat buttonWidth;
    CGFloat bookmarkButtonX;
    if (o == UIInterfaceOrientationPortrait ||
        o == UIInterfaceOrientationPortraitUpsideDown) {
        buttonWidth = 147;
        bookmarkButtonX = 164;
    } else {
        buttonWidth = 227;
        bookmarkButtonX = 244;
    }

    CGRect blockButtonFrame = blockButton.frame;
    blockButtonFrame.size.width = buttonWidth;
    blockButton.frame = blockButtonFrame;

    CGRect bookmarkButtonFrame = bookmarkButton.frame;
    bookmarkButtonFrame.size.width = buttonWidth;
    bookmarkButtonFrame.origin.x = bookmarkButtonX;
    bookmarkButton.frame = bookmarkButtonFrame;
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

- (CGFloat)tableView:(UITableView *)tv
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kUserInfoSectionDetails ? 64 : 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    NSString * formatString;
    UserInfoLabelCell * userInfoLabelCell;
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    switch (indexPath.section) {
        case kUserInfoSectionDetails:
            [self.locationCell setLandscape:landscape];
            cell = self.locationCell;
            break;
        case kUserInfoSectionNetwork:
            cell = [self getLabelCell];
            userInfoLabelCell = (UserInfoLabelCell *)cell;
            cell.accessoryType =
                UITableViewCellAccessoryDisclosureIndicator;

            NSNumberFormatter * formatter =
                [[[NSNumberFormatter alloc] init] autorelease];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
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
                    setValueText:
                    [formatter stringFromNumber:user.followersCount]];
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
                    setValueText:
                    [formatter stringFromNumber:user.friendsCount]];
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
                    setValueText:
                    [formatter stringFromNumber:user.statusesCount]];
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
                    [UIImage imageNamed:@"PublicMessageButtonIcon.png"] :
                    [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
                cell.imageView.highlightedImage =
                    indexPath.row == kUserInfoPublicMessage ?
                    [UIImage
                    imageNamed:@"PublicMessageButtonIconHighlighted.png"] :
                    [UIImage imageNamed:@"DirectMessageButtonIcon.png"];
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
        avatarImage &&
        ([user.avatar.thumbnailImageUrl isEqual:urlAsString] ||
        [user.avatar.fullImageUrl isEqual:urlAsString]))
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

    // sucks but the map span doesn't seem to set properly if we don't recreate
    if (locationCell) {
        [locationCell release];
        locationCell = nil;
    }

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

    blockButton.enabled = blockedStateSet;

    UIImage * avatar = [user fullAvatar];
    if (!avatar)
        avatar = [user thumbnailAvatar];
    if (!avatar)
        avatar = [[self class] defaultAvatar];

    [avatarView setImage:avatar];

    NSURL * largeAvatarUrl = [NSURL URLWithString:user.avatar.fullImageUrl];
    NSURL * avatarUrl = [NSURL URLWithString:user.avatar.thumbnailImageUrl];
    [AsynchronousNetworkFetcher fetcherWithUrl:largeAvatarUrl delegate:self];
    [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];

    UIImage * avatarImage = [user thumbnailAvatar];
    if (avatarImage)
        [avatarView setImage:avatarImage];

    nameLabel.text = aUser.name;
    bioLabel.text = [aUser.bio stringByDecodingHtmlEntities];

    if (user.webpage) {
        [webAddressButton setTitle:user.webpage forState:UIControlStateNormal];
        [webAddressButton setTitle:user.webpage
            forState:UIControlStateHighlighted];
    }

    [self.locationCell setLocationText:user.location];

    bookmarkButton.enabled =
        ![findPeopleBookmarkMgr isSearchSaved:user.username];

    [self layoutViews];
    [self.tableView reloadData];
}

- (void)showingNewUser
{
    followingStateSet = NO;
    blockedStateSet = NO;
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

- (void)setFailedToQueryFollowing
{
    followingActivityIndicator.hidden = YES;
    followingLoadingLabel.hidden = YES;
    followButton.hidden = YES;
    stopFollowingButton.hidden = YES;
}

- (void)setBlocked:(BOOL)blocked
{
    currentlyBlocked = blocked;
    blockedStateSet = YES;
    blockButton.enabled = YES;

    NSString * title =
        blocked ?
        NSLocalizedString(@"userinfo.unblock", @"") :
        NSLocalizedString(@"userinfo.block", @"");
    [blockButton setTitle:title forState:UIControlStateNormal];
}

- (void)setFailedToQueryBlocked
{
    blockButton.enabled = NO;
}

- (void)layoutViews
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    
    CGFloat labelWidth = landscape ? 440 : 280;

    CGRect bioLabelFrame = bioLabel.frame;
    bioLabelFrame.size.width = labelWidth;
    bioLabel.frame = bioLabelFrame;

    bioLabelFrame.size.height = [bioLabel heightForString:bioLabel.text];
    bioLabel.frame = bioLabelFrame;

    webAddressButton.hidden = !user.webpage;
    CGRect webAddressFrame = webAddressButton.frame;
    webAddressFrame.origin.y =
        bioLabel.text.length > 0 ?
        bioLabelFrame.size.height + 388.0 : 388.0;
    webAddressFrame.size.width = labelWidth;
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

- (IBAction)changeBlockedState:(id)sender
{
    blockButton.enabled = NO;
    if (currentlyBlocked)
        [delegate unblockUser:user.username];
    else
        [delegate blockUser:user.username];
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

    if (!cell) {
        cell =
            [[[UITableViewCell alloc]
            initWithFrame:CGRectZero reuseIdentifier:cellIdentifier]
            autorelease];

        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            cell.backgroundColor =
                [TimelineTableViewCellView defaultDarkThemeCellColor];
            cell.textLabel.textColor = [UIColor whiteColor];
        }
    }

    return cell;
}

- (UITableViewCell *)getLabelCell
{
    static NSString * cellIdentifier = @"UserInfoLabelCell";

    UserInfoLabelCell * cell =
        (UserInfoLabelCell *)
        [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        NSArray * nib =
            [[NSBundle mainBundle]
            loadNibNamed:cellIdentifier owner:self options:nil];

        cell = [nib objectAtIndex:0];
        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            cell.backgroundColor =
                [TimelineTableViewCellView defaultDarkThemeCellColor];
            [cell setKeyColor:[UIColor twitchBlueOnDarkBackgroundColor]];
            [cell setValueColor:[UIColor whiteColor]];
        }
    }

    return cell;
}

- (LocationCell *)locationCell
{
    if (!locationCell) {
        locationCell =
            [[LocationCell alloc] initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:@"LocationCell"];
        if ([SettingsReader displayTheme] == kDisplayThemeDark) {
            locationCell.backgroundColor =
                [TimelineTableViewCellView defaultDarkThemeCellColor];
            [locationCell setLabelTextColor:[UIColor whiteColor]];
        }
    }

    return locationCell;
}

+ (UIImage *)defaultAvatar
{
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar.png"] retain];

    return defaultAvatar;
}

@end
