//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController, selectedTweet, updateId;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [tweetDetailsController release];

    [service release];

    [selectedTweet release];
    [timeline release];
    [updateId release];
        
    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(TwitterService *)aService
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

        if(service.credentials)
            [service fetchTimelineSinceUpdateId:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]
            count:[NSNumber numberWithInt:0]];
    }

    return self;
}

#pragma mark TwitterServiceDelegate implementation

- (void)timeline:(NSArray *)aTimeline
    fetchedSinceUpdateId:(NSNumber *)anUpdateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSLog(@"Timeline received: %@", aTimeline);
    self.updateId = anUpdateId;
    for (Tweet * tweet in aTimeline)
        [timeline setObject:tweet forKey:tweet.identifier];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
    [timelineController setTweets:[timeline allValues] page:[page intValue]];
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    // TODO: display alert view
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(Tweet *)tweet
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
    [wrapperController setCachedDataAvailable:!!timeline];
    if(service.credentials)
        [service fetchTimelineSinceUpdateId:[NSNumber numberWithInt:0]
        page:[NSNumber numberWithInt:++pagesShown]
        count:[NSNumber numberWithInt:0]];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)selectedUser:(User *)user
{
    NSLog(@"Selected user: %@", user);
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
    [wrapperController setCachedDataAvailable:!!timeline];
    if(service.credentials)
        [service fetchTimelineSinceUpdateId:self.updateId
            page:[NSNumber numberWithInt:0] count:[NSNumber numberWithInt:0]];
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

- (void)setCredentials:(TwitterCredentials *)credentials
{
    NSLog(@"New credentials set");
    service.credentials = credentials;
    [service fetchTimelineSinceUpdateId:[NSNumber numberWithInt:0]
        page:[NSNumber numberWithInt:pagesShown]
        count:[NSNumber numberWithInt:0]];
}

@end
