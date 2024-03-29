//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgrFactory.h"
#import "TwitterService.h"
#import "CredentialsActivatedPublisher.h"
#import "CredentialsSetChangedPublisher.h"
#import "AllTimelineDataSource.h"
#import "UserListDisplayMgrFactory.h"
#import "MyFavoritesTimelineDataSource.h"
#import "RetweetsDataSource.h"

@implementation TimelineDisplayMgrFactory

- (void)dealloc
{
    [context release];
    [findPeopleBookmarkMgr release];
    [contactCache release];
    [contactMgr release];
    [super dealloc];
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr
{
    if (self = [super init]) {
        context = [someContext retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
        contactCache = [aContactCache retain];
        contactMgr = [aContactMgr retain];
    }

    return self;
}

- (TimelineDisplayMgr *)
    createTimelineDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
    title:(NSString *)title
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
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

    TwitterService * timelineService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];

    UserListDisplayMgrFactory * userListDisplayMgrFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:context findPeopleBookmarkMgr:findPeopleBookmarkMgr
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];

    TimelineDisplayMgr * timelineDisplayMgr =
        [[[TimelineDisplayMgr alloc]
        initWithWrapperController:wrapperController
        navigationController:navigationController
        timelineController:timelineController timelineSource:dataSource
        service:timelineService title:title factory:self
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        userListDisplayMgrFactory:userListDisplayMgrFactory
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];
    timelineDisplayMgr.autoUpdate = YES;
    dataSource.delegate = timelineDisplayMgr;
    timelineController.delegate = timelineDisplayMgr;
    wrapperController.delegate = timelineDisplayMgr;
    timelineService.delegate = timelineDisplayMgr;

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:timelineDisplayMgr action:@selector(setCredentials:)];

    [[CredentialsSetChangedPublisher alloc]
        initWithListener:timelineDisplayMgr
        action:@selector(credentialsSetChanged:added:)];

    return timelineDisplayMgr;
}

- (TimelineDisplayMgr *)
    createFavoritesDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
    title:(NSString *)title
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
{
    TimelineViewController * timelineController =
        [[[TimelineViewController alloc]
        initWithNibName:@"TimelineView" bundle:nil] autorelease];
    wrapperController.targetViewController = timelineController;

    TwitterService * service =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];
    MyFavoritesTimelineDataSource * dataSource =
        [[[MyFavoritesTimelineDataSource alloc] initWithTwitterService:service]
        autorelease];
    service.delegate = dataSource;

    TwitterService * timelineService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];

    UserListDisplayMgrFactory * userListDisplayMgrFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:context findPeopleBookmarkMgr:findPeopleBookmarkMgr
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];

    TimelineDisplayMgr * timelineDisplayMgr =
        [[[TimelineDisplayMgr alloc]
        initWithWrapperController:wrapperController
        navigationController:navigationController
        timelineController:timelineController timelineSource:dataSource
        service:timelineService title:title factory:self
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        userListDisplayMgrFactory:userListDisplayMgrFactory
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];
    timelineDisplayMgr.autoUpdate = YES;
    dataSource.delegate = timelineDisplayMgr;
    timelineController.delegate = timelineDisplayMgr;
    wrapperController.delegate = timelineDisplayMgr;
    timelineService.delegate = timelineDisplayMgr;

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:timelineDisplayMgr action:@selector(setCredentials:)];

    [[CredentialsSetChangedPublisher alloc]
        initWithListener:timelineDisplayMgr
        action:@selector(credentialsSetChanged:added:)];

    return timelineDisplayMgr;
}

- (TimelineDisplayMgr *)
    createRetweetsDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
    title:(NSString *)title
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
{
    TimelineViewController * timelineController =
        [[[TimelineViewController alloc]
        initWithNibName:@"TimelineView" bundle:nil] autorelease];
    wrapperController.targetViewController = timelineController;

    TwitterService * service =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];
    RetweetsDataSource * dataSource =
        [[[RetweetsDataSource alloc] initWithTwitterService:service]
        autorelease];
    service.delegate = dataSource;

    TwitterService * timelineService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];

    UserListDisplayMgrFactory * userListDisplayMgrFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:context findPeopleBookmarkMgr:findPeopleBookmarkMgr
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];

    TimelineDisplayMgr * timelineDisplayMgr =
        [[[TimelineDisplayMgr alloc]
        initWithWrapperController:wrapperController
        navigationController:navigationController
        timelineController:timelineController timelineSource:dataSource
        service:timelineService title:title factory:self
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        userListDisplayMgrFactory:userListDisplayMgrFactory
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];
    timelineDisplayMgr.autoUpdate = YES;
    dataSource.delegate = timelineDisplayMgr;
    timelineController.delegate = timelineDisplayMgr;
    wrapperController.delegate = timelineDisplayMgr;
    timelineService.delegate = timelineDisplayMgr;

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:timelineDisplayMgr action:@selector(setCredentials:)];

    [[CredentialsSetChangedPublisher alloc]
        initWithListener:timelineDisplayMgr
        action:@selector(credentialsSetChanged:added:)];

    return timelineDisplayMgr;
}
    
@end
