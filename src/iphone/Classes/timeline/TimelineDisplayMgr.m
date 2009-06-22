//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
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

        if(service.credentials)
            //[service fetchTimelineSinceUpdateId:0 page:0 count:0];
            [service fetchDirectMessagesSinceId:0 page:0];
    }

    return self;
}

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

- (void)setCredentials:(TwitterCredentials *)credentials
{
    NSLog(@"New credentials set");
    service.credentials = credentials;
    //[service fetchTimelineSinceUpdateId:0 page:0 count:0];
    [service fetchDirectMessagesSinceId:0 page:0];
}

@end
