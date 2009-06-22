//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgrFactory.h"
#import "TwitterService.h"
#import "CredentialsUpdatePublisher.h"
#import "AllTimelineDataSource.h"
#import "AllTimelineDataSource.h"

@implementation TimelineDisplayMgrFactory

- (void)dealloc
{
    [context release];
    [super dealloc];
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
{
    if (self = [super init])
        context = [someContext retain];

    return self;
}

- (TimelineDisplayMgr *)
    createTimelineDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
{
    TimelineViewController * timelineController =
        [[[TimelineViewController alloc]
        initWithNibName:@"TimelineView" bundle:nil] autorelease];
    wrapperController.targetViewController = timelineController;

    TwitterService * service =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];
    AllTimelineDataSource * dataSource =
        [[[AllTimelineDataSource alloc] initWithTwitterService:service]
        autorelease];
    service.delegate = dataSource;

    TimelineDisplayMgr * timelineDisplayMgr =
        [[[TimelineDisplayMgr alloc] initWithWrapperController:wrapperController
        timelineController:timelineController service:dataSource]
        autorelease];
    dataSource.delegate = timelineDisplayMgr;
    timelineController.delegate = timelineDisplayMgr;

    // Don't autorelease
    [[CredentialsUpdatePublisher alloc]
        initWithListener:timelineDisplayMgr action:@selector(setCredentials:)];

    return timelineDisplayMgr;
}
    
@end
