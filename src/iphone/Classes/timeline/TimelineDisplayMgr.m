//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"

@interface TimelineDisplayMgr ()

- (BOOL)cachedDataAvailable;

@end

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController, userInfoController,
    selectedTweet, updateId, user, timeline, pagesShown, displayAsConversation,
    setUserToFirstTweeter;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [tweetDetailsController release];

    [service release];

    [selectedTweet release];
    [user release];
    [timeline release];
    [updateId release];
        
    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(NSObject<TimelineDataSource> *)aService title:(NSString *)title
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        timelineController = [aTimelineController retain];
        service = [aService retain];

        timeline = [[NSMutableDictionary dictionary] retain];

        pagesShown = 1;

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        [wrapperController setCachedDataAvailable:NO];
        wrapperController.title = title;
    }

    return self;
}

#pragma mark TimelineDataSourceDelegate implementation

- (void)timeline:(NSArray *)aTimeline
    fetchedSinceUpdateId:(NSNumber *)anUpdateId page:(NSNumber *)page
{
    NSLog(@"Timeline received: %@", aTimeline);
    self.updateId = anUpdateId;
    for (TweetInfo * tweet in aTimeline)
        [timeline setObject:tweet forKey:tweet.identifier];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
    if (setUserToFirstTweeter) {
        timelineController.showWithoutAvatars = YES;
        if ([aTimeline count] > 0) {
            TweetInfo * firstTweet = [aTimeline objectAtIndex:0];
            [timelineController setUser:firstTweet.user];
            self.user = firstTweet.user;
        } else {
            // TODO: fetch user from credentials username
        }
    }
    [timelineController setTweets:[timeline allValues] page:pagesShown];
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error
{
    // TODO: display alert view
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(TweetInfo *)tweet avatarImage:(UIImage *)avatarImage
{
    NSLog(@"Selected tweet: %@", tweet);
    self.selectedTweet = tweet;
    [self.wrapperController.navigationController
        pushViewController:self.tweetDetailsController animated:YES];
    [self.tweetDetailsController setTweet:tweet avatar:avatarImage];
}

- (void)loadMoreTweets
{
    NSLog(@"Loading more tweets...");
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
    if ([service credentials])
        [service fetchTimelineSince:[NSNumber numberWithInt:0]
        page:[NSNumber numberWithInt:++pagesShown]];
}

- (void)showUserInfoWithAvatar:(UIImage *)avatar
{
    NSLog(@"Showing user info for %@", user);
    [self.wrapperController.navigationController
        pushViewController:self.userInfoController animated:YES];
    [self.userInfoController setUser:user avatarImage:avatar];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)selectedUser:(User *)aUser
{
    NSLog(@"Selected user: %@", aUser);
}

- (void)setFavorite:(BOOL)favorite
{
}

- (void)replyToTweet
{
    NSLog(@"Reply to tweet selected");
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    if ((!hasBeenDisplayed && [service credentials]) || needsRefresh) {
        NSLog(@"Fetching new timeline on display...");
        [service fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]];
    }

    hasBeenDisplayed = YES;
    needsRefresh = NO;
}

#pragma mark TimelineDisplayMgr implementation

- (void)refresh
{
    NSLog(@"Refreshing timeline...");
    if([service credentials])
        [service fetchTimelineSince:self.updateId
            page:[NSNumber numberWithInt:0]];
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
}

- (void)addTweet:(Tweet *)tweet displayImmediately:(BOOL)displayImmediately
{
    TweetInfo * info = [TweetInfo createFromTweet:tweet];
    [timeline setObject:info forKey:info.identifier];

    if (displayImmediately)
        [timelineController addTweet:info];
}

- (BOOL)cachedDataAvailable
{
    return !!timeline && [timeline count] > 0;
}

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"Showing %@ on map", locationString);
    NSString * locationWithoutCommas =
        [locationString stringByReplacingOccurrencesOfString:@"iPhone:"
        withString:@""];
    NSString * urlString =
        [[NSString
        stringWithFormat:@"http://maps.google.com/maps?q=%@",
        locationWithoutCommas]
        stringByAddingPercentEscapesUsingEncoding:
        NSUTF8StringEncoding];
    NSURL * url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)visitWebpage:(NSString *)webpageUrl
{
    NSLog(@"Visiting webpage: %@", webpageUrl);
}

- (void)displayFollowingForUser:(NSString *)username
{
    NSLog(@"Displaying 'following' list for %@", username);
}

- (void)displayFollowersForUser:(NSString *)username
{
    NSLog(@"Displaying 'followers' set for %@", username);
}

- (void)startFollowingUser:(NSString *)username
{
    NSLog(@"Sending 'follow user' request for %@", username);
}

- (void)stopFollowingUser:(NSString *)username
{
    NSLog(@"Sending 'stop following' request for %@", username);
}

#pragma mark Accessors

- (TweetDetailsViewController *)tweetDetailsController
{
    if (!tweetDetailsController) {
        tweetDetailsController =
            [[TweetDetailsViewController alloc]
            initWithNibName:@"TweetDetailsView" bundle:nil];

        UIBarButtonItem * replyButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self
            action:@selector(replyToTweet)]
            autorelease];
        [tweetDetailsController.navigationItem
            setRightBarButtonItem:replyButton];

        NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
        tweetDetailsController.navigationItem.title = title;

        tweetDetailsController.navigationItem.hidesBackButton = NO;

        tweetDetailsController.delegate = self;
    }

    return tweetDetailsController;
}

- (UserInfoViewController *)userInfoController
{
    if (!userInfoController) {
        userInfoController =
            [[UserInfoViewController alloc]
            initWithNibName:@"UserInfoView" bundle:nil];

        NSString * title = NSLocalizedString(@"userinfoview.title", @"");
        userInfoController.navigationItem.title = title;

        userInfoController.delegate = self;
    }

    return userInfoController;
}

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh
{
    [aService retain];
    [service release];
    service = aService;

    [timeline removeAllObjects];
    [timeline addEntriesFromDictionary:someTweets];

    pagesShown = page;

    [aService setCredentials:credentials];

    [self.timelineController.tableView
        scrollRectToVisible:self.timelineController.tableView.frame
        animated:NO];

    [timelineController setTweets:[timeline allValues] page:pagesShown];

    if (refresh)
        [self refresh];
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Setting new credentials on timeline display manager...");

    TwitterCredentials * oldCredentials = credentials;

    [someCredentials retain];
    [credentials autorelease];
    credentials = someCredentials;

    if (displayAsConversation) {
        NSArray * invertedCellUsernames =
            [NSArray arrayWithObject:someCredentials.username];
        self.timelineController.invertedCellUsernames = invertedCellUsernames;
    }

    [service setCredentials:credentials];

    if (oldCredentials &&
        ![oldCredentials.username isEqual:credentials.username]) {
        // Changed accounts (as opposed to setting it for the first time)

        [timeline removeAllObjects];
        needsRefresh = YES;
        pagesShown = 1;
        [self.wrapperController setCachedDataAvailable:NO];
        [self.wrapperController setUpdatingState:kConnectedAndUpdating];
    } else if (hasBeenDisplayed) // set for first time and persisted data shown
        [service fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]];
}

- (void)setUser:(User *)aUser
{
    [aUser retain];
    [user release];
    user = aUser;

    [self.timelineController setUser:aUser];
}

- (NSMutableDictionary *)timeline
{
    return [[timeline copy] autorelease];
}

- (void)setDisplayAsConversation:(BOOL)conversation
{
    displayAsConversation = conversation;
    NSArray * invertedCellUsernames =
        conversation && !!credentials ?
        [NSArray arrayWithObject:credentials.username] : [NSArray array];
    self.timelineController.invertedCellUsernames = invertedCellUsernames;
}

@end
