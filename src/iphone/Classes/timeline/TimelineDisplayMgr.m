//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"

@interface TimelineDisplayMgr ()

- (BOOL)cachedDataAvailable;

@end

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController, selectedTweet, updateId,
    user, timeline, pagesShown;

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
    service:(NSObject<TimelineDataSource> *)aService
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        timelineController = [aTimelineController retain];
        service = [aService retain];

        timeline = [[NSMutableDictionary dictionary] retain];

        pagesShown = 1;

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        [wrapperController setCachedDataAvailable:NO];
        wrapperController.title = @"Timeline";

        if ([service credentials])
            [service fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]];
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
    [timelineController setTweets:[timeline allValues] page:pagesShown];
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error
{
    // TODO: display alert view
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(TweetInfo *)tweet
{
    NSLog(@"Selected tweet: %@", tweet);
    self.selectedTweet = tweet;
    [self.wrapperController.navigationController
        pushViewController:self.tweetDetailsController animated:YES];
    [self.tweetDetailsController setTweet:tweet];
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

#pragma mark TimelineDisplayMgr implementation

- (void)refresh
{
    NSLog(@"Refreshing timeline...");
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
    if([service credentials])
        [service fetchTimelineSince:self.updateId
            page:[NSNumber numberWithInt:0]];
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

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
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

    [self refresh];
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"New credentials set");
    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:credentials];
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

@end
