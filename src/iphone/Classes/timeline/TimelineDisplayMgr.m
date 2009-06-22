//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController, selectedTweet;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [tweetDetailsController release];

    [service release];
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

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        [wrapperController setCachedDataAvailable:NO];
        wrapperController.title = @"Timeline";

        if(service.credentials)
            [service fetchTimelineSince:0 page:0 count:0];
    }

    return self;
}

#pragma mark TwitterServiceDelegate implementation

- (void)timeline:(NSArray *)timeline fetchedSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count
{
    NSLog(@"Timeline received: %@", timeline);
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
    [timelineController setTweets:timeline];
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

- (void)setCredentials:(TwitterCredentials *)credentials
{
    NSLog(@"New credentials set");
    service.credentials = credentials;
    [service fetchTimelineSince:0 page:0 count:0];
}

- (void)replyToTweet
{
    NSLog(@"Reply to tweet selected");
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)selectedUser:(User *)user
{
    NSLog(@"Selected user: %@", user);
}

- (void)setFavorite:(BOOL)favorite
{
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

@end
