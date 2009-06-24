//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserListTableViewController.h"
#import "UserSummaryTableViewCell.h"
#import "User.h"
#import "AsynchronousNetworkFetcher.h"
#import "UIColor+TwitchColors.h"

@interface UserListTableViewController ()

- (UIImage *)getAvatarForUrl:(NSString *)url;

@end

@implementation UserListTableViewController

@synthesize delegate;

- (void)dealloc
{
    [footerView release];
    [currentPagesLabel release];
    [loadMoreButton release];

    [users release];
    [avatarCache release];
    [alreadySent release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    avatarCache = [[NSMutableDictionary dictionary] retain];
    alreadySent = [[NSMutableDictionary dictionary] retain];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return [users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"UserSummaryTableViewCell";

    UserSummaryTableViewCell * cell =
        (UserSummaryTableViewCell *)
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray * nib =
            [[NSBundle mainBundle] loadNibNamed:@"UserSummaryTableViewCell"
            owner:self options:nil];

        cell = [nib objectAtIndex:0];
    }

    User * user = [users objectAtIndex:indexPath.row];
    [cell setAvatar:[self getAvatarForUrl:user.profileImageUrl]];
    [cell setName:user.name];
    [cell setUsername:user.username];
    NSString * followingText =
        NSLocalizedString(@"userlisttableview.following", @"");
    [cell setFollowingText:followingText];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User * user = [users objectAtIndex:indexPath.row];
    [delegate showTweetsForUser:user.username];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSLog(@"Received avatar for url: %@", url);
    NSString * urlAsString = [url absoluteString];
    UIImage * avatarImage = [UIImage imageWithData:data];
    [avatarCache setObject:avatarImage forKey:urlAsString];
    [self.tableView reloadData];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark UserListTableViewController implementation

- (void)setUsers:(NSArray *)someUsers
{
    NSArray * tempUsers = [someUsers copy];
    [users release];
    users = tempUsers;
    
    [loadMoreButton setTitleColor:[UIColor twitchBlueColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = YES;
    
    [self.tableView reloadData];
}

- (UIImage *)getAvatarForUrl:(NSString *)url
{
    UIImage * avatarImage = [avatarCache objectForKey:url];
    if (!avatarImage) {
        avatarImage = [UIImage imageNamed:@"DefaultAvatar.png"];
        if (![alreadySent objectForKey:url]) {
            NSURL * avatarUrl = [NSURL URLWithString:url];
            [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
            [alreadySent setObject:url forKey:url];
        }
    }

    return avatarImage;
}

- (IBAction)loadMoreUsers:(id)sender
{
    NSLog(@"'Load more users' selected");
    [delegate loadMoreUsers];
    [loadMoreButton setTitleColor:[UIColor grayColor]
        forState:UIControlStateNormal];
    loadMoreButton.enabled = NO;
}

@end
