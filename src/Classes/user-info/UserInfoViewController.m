//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserInfoViewController.h"
#import "UILabel+DrawingAdditions.h"
#import "UIColor+TwitchColors.h"
#import "UserInfoLabelCell.h"
#import "AsynchronousNetworkFetcher.h"

enum {
    kUserInfoSectionDetails,
    kUserInfoSectionNetwork
};

enum {
    kUserInfoFollowingRow,
    kUserInfoFollowersRow,
    kUserInfoFavoritesRow
};

@interface UserInfoViewController ()

- (void)layoutViews;
- (void)updateDisplayForFollwoing:(BOOL)following;

@end

@implementation UserInfoViewController

@synthesize delegate, followingEnabled;

- (void)dealloc
{
    [headerView release];
    [footerView release];
    [avatarView release];
    [nameLabel release];
    [usernameLabel release];
    [bioLabel release];

    [followingLabel release];
    [followingCheckMark release];
    [followingActivityIndicator release];
    [followingLoadingLabel release];

    [followButton release];
    [sendMessageButton release];

    [user release];

    [super dealloc];
}

- (void)viewDidLoad
{
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
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
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
        numRows = 3;

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

                if (indexPath.row == kUserInfoFavoritesRow)
                    cell.textLabel.text =
                        NSLocalizedString(@"userinfoview.favorites", @"");
                else {
                    if (indexPath.row == kUserInfoFollowersRow) {
                        if ([user.followersCount
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
                        formatString =
                            NSLocalizedString(@"userinfoview.followers", @"");
                        count = user.followersCount;
                    } else {
                        if ([user.friendsCount
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
                        formatString =
                            NSLocalizedString(@"userinfoview.following", @"");
                        count = user.friendsCount;
                    }

                    cell.textLabel.text =
                        [NSString stringWithFormat:formatString, count];
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
                [delegate visitWebpage:user.webpage];
            break;
        case kUserInfoSectionNetwork:
            if (indexPath.row == kUserInfoFollowingRow)
                [delegate displayFollowingForUser:user.username];
            else if (indexPath.row == kUserInfoFollowersRow)
                [delegate displayFollowersForUser:user.username];
            else
                [delegate displayFavoritesForUser:user.username];
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
    [avatarView setImage:avatarImage];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark UserInfoViewController implementation

- (void)setUser:(User *)aUser avatarImage:(UIImage *)avatarImage
{
    [aUser retain];
    [user release];
    user = aUser;

    if (followingEnabled) {
        followingLabel.hidden = YES;
        followingCheckMark.hidden = YES;
        followingActivityIndicator.hidden = NO;
        followingLoadingLabel.hidden = NO;
        followButton.enabled = NO;
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
        followButton.enabled = NO;
        [followButton setTitleColor:[UIColor grayColor]
            forState:UIControlStateNormal];
        NSString * followingBtnText =
            NSLocalizedString(@"userinfoview.startfollowing", @"");
        [followButton setTitle:followingBtnText forState:UIControlStateNormal];
    }

    if (!avatarImage) {
        NSURL * avatarUrl = [NSURL URLWithString:user.profileImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
        [avatarView setImage:[UIImage imageNamed:@"DefaultAvatar.png"]];
    } else
        [avatarView setImage:avatarImage];
    nameLabel.text = aUser.name;
    usernameLabel.text = [NSString stringWithFormat:@"@%@", aUser.username];
    bioLabel.text = aUser.bio;

    [self layoutViews];
    [self.tableView reloadData];
}

- (void)setFollowing:(BOOL)following
{
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
    headerViewFrame.size.height = bioLabelFrame.size.height + 390.0;
    headerView.frame = headerViewFrame;

    // force the header view to redraw
    self.tableView.tableHeaderView = headerView;
}

- (IBAction)toggleFollowing:(id)sender
{   
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

- (void)updateDisplayForFollwoing:(BOOL)following
{
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

@end
