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
    kUserInfoFollowersRow
};

@interface UserInfoViewController ()

- (void)layoutViews;

@end

@implementation UserInfoViewController

@synthesize delegate;

- (void)dealloc
{
    [headerView release];
    [footerView release];
    [avatarView release];
    [nameLabel release];
    [usernameLabel release];
    [bioLabel release];
    [followingLabel release];
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
                    formatString =
                        NSLocalizedString(@"userinfoview.followers", @"");
                    count = user.followersCount;
                } else {
                    formatString =
                        NSLocalizedString(@"userinfoview.following", @"");
                    count = user.friendsCount;
                }
                cell.textLabel.text =
                    [NSString stringWithFormat:formatString, count];
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
            if (indexPath.row == 0)
                [delegate displayFollowersForUser:user.username];
            else
                [delegate displayFollowingForUser:user.username];
            break;
    }
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    UIImage * avatarImage = [UIImage imageWithData:data];
    avatarView.imageView.image = avatarImage;
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

    if (!avatarImage) {
        NSURL * avatarUrl = [NSURL URLWithString:user.profileImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
        avatarView.imageView.image = [UIImage imageNamed:@"DefaultAvatar.png"];
    } else
        avatarView.imageView.image = avatarImage;
    nameLabel.text = aUser.name;
    usernameLabel.text = [NSString stringWithFormat:@"@%@", aUser.username];
    bioLabel.text = aUser.bio;

    [self layoutViews];
}

- (void)layoutViews
{
    CGRect bioLabelFrame = bioLabel.frame;
    bioLabelFrame.size.height = [bioLabel heightForString:bioLabel.text];
    bioLabel.frame = bioLabelFrame;

    CGRect headerViewFrame = headerView.frame;
    headerViewFrame.size.height = bioLabelFrame.size.height + 72.0;
    headerView.frame = headerViewFrame;

    // force the header view to redraw
    self.tableView.tableHeaderView = headerView;
}

- (IBAction)toggleFollowing:(id)sender
{
    [delegate startFollowingUser:user.username];
}

- (IBAction)sendMessage:(id)sender
{
}

@end

