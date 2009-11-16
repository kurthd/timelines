//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ListsDisplayMgr.h"
#import "ListsViewController.h"
#import "ErrorState.h"
#import "TwitterList.h"
#import "ListTimelineDataSource.h"

@interface ListsDisplayMgr ()

@property (nonatomic, copy) NSString * listsCursor;
@property (nonatomic, copy) NSString * subscriptionsCursor;
@property (nonatomic, retain) NSMutableDictionary * lists;
@property (nonatomic, retain) NSMutableDictionary * subscriptions;

@property (nonatomic, retain)
    NetworkAwareViewController * nextWrapperController;
@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;

- (void)fetchListsFromCursor:(NSString *)cursor;
- (void)fetchListSubscriptionsFromCursor:(NSString *)cursor;
- (void)updateViewWithNewLists;
- (void)updateViewForOutstandingQueries;

@end

@implementation ListsDisplayMgr

@synthesize fetchedInitialLists;
@synthesize listsCursor, subscriptionsCursor;
@synthesize lists, subscriptions;
@synthesize nextWrapperController, timelineDisplayMgr, credentialsPublisher;

- (void)dealloc
{
    [wrapperController release];
    [navigationController release];
    [listsViewController release];
    [service release];
    [timelineDisplayMgrFactory release];
    [composeTweetDisplayMgr release];
    [context release];

    [listsViewController release];
    [subscriptionsCursor release];
    [lists release];
    [subscriptions release];

    [nextWrapperController release];
    [timelineDisplayMgr release];
    [credentialsPublisher release];

    [credentials release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)aNavigationController
    listsViewController:(ListsViewController *)aListsViewController
    service:(TwitterService *)aService
    factory:(TimelineDisplayMgrFactory *)aTimelineDisplayMgrFactory
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        navigationController = [aNavigationController retain];
        listsViewController = [aListsViewController retain];
        service = [aService retain];
        timelineDisplayMgrFactory = [aTimelineDisplayMgrFactory retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        context = [aContext retain];

        [self resetState];
    }

    return self;
}

#pragma mark TwitterServiceDelegate implementation

- (void)lists:(NSArray *)someLists fetchedFromCursor:(NSString *)cursor
    nextCursor:(NSString *)nextCursor
{
    self.listsCursor = nextCursor;

    for (TwitterList * list in someLists)
        [self.lists setObject:list forKey:list.identifier];

    outstandingListRequests--;
    [self updateViewWithNewLists];
    [[ErrorState instance] exitErrorState];
}
    
- (void)failedToFetchListsFromCursor:(NSString *)cursor error:(NSError *)error
{
    NSLog(@"Lists Display Manager: failed to fetch lists from cursor %@",
        cursor);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"listsdisplaymgr.error.fetchlists", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
        retryTarget:self retryAction:@selector(refreshLists)];
    [wrapperController setUpdatingState:kDisconnected];

    outstandingListRequests--;
}

- (void)listSubscriptions:(NSArray *)listSubscriptions
    fetchedFromCursor:(NSString *)cursor nextCursor:(NSString *)nextCursor
{
    self.subscriptionsCursor = nextCursor;

    for (TwitterList * list in listSubscriptions)
        [self.subscriptions setObject:list forKey:list.identifier];

    outstandingListSubscriptionRequests--;
    [self updateViewWithNewLists];
    [[ErrorState instance] exitErrorState];
}

- (void)failedToFetchListSubscriptionsFromCursor:(NSString *)cursor
    error:(NSError *)error
{
    NSLog(
        @"Lists Display Manager: failed to fetch subscriptions from cursor %@",
        cursor);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"listsdisplaymgr.error.fetchlists", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
        retryTarget:self retryAction:@selector(refreshLists)];
    [wrapperController setUpdatingState:kDisconnected];

    outstandingListSubscriptionRequests--;
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Lists view will appear");
    if (!fetchedInitialLists && outstandingListRequests == 0 &&
        outstandingListSubscriptionRequests == 0) {

        listRequestType = kListRequestTypeInitial;
        [self fetchListsFromCursor:nil];
        [self fetchListSubscriptionsFromCursor:nil];

        [self updateViewForOutstandingQueries];
    }
}

#pragma mark ListsViewControllerDelegate implementation

- (void)userDidSelectListWithId:(NSNumber *)identifier
{
    NSLog(@"User selected list with id: %@", identifier);

    TwitterList * list = [lists objectForKey:identifier];
    if (!list)
        list = [subscriptions objectForKey:identifier];

    NSString * title = list.name;
    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:nextWrapperController
        navigationController:navigationController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = YES;
    self.timelineDisplayMgr.setUserToFirstTweeter = NO;
    [self.timelineDisplayMgr setCredentials:credentials];

    self.nextWrapperController.delegate = self.timelineDisplayMgr;

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil context:context]
        autorelease];

    ListTimelineDataSource * dataSource =
        [[[ListTimelineDataSource alloc]
        initWithTwitterService:twitterService username:list.user.username
        listId:list.identifier]
        autorelease];

    self.credentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [self.timelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.timelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [navigationController pushViewController:self.nextWrapperController
        animated:YES];
}

#pragma mark Public implementation

- (void)resetState
{
    NSLog(@"Resetting list display manager state...");
    fetchedInitialLists = NO;
    pagesShown = 0;
    self.lists = [NSMutableDictionary dictionary];
    self.subscriptions = [NSMutableDictionary dictionary];
    [wrapperController setCachedDataAvailable:NO];
}

- (void)refreshLists
{
    NSLog(@"Refreshing lists...");
    if (outstandingListRequests == 0 &&
        outstandingListSubscriptionRequests == 0) {

        listRequestType = kListRequestTypeRefresh;
        [self fetchListsFromCursor:nil];
        [self fetchListSubscriptionsFromCursor:nil];

        [self updateViewForOutstandingQueries];
    }
}

- (void)loadMoreLists
{
    NSLog(@"Loading more lists...");
    if (outstandingListRequests == 0 &&
        outstandingListSubscriptionRequests == 0) {

        listRequestType = kListRequestTypeLoadMore;
        [self fetchListsFromCursor:self.listsCursor];
        [self fetchListSubscriptionsFromCursor:self.subscriptionsCursor];
        
        [self updateViewForOutstandingQueries];
    }
}

- (void)displayLists:(NSArray *)someLists
{
    self.listsCursor = nil;  // assume we need to start paging from here

    [self.lists removeAllObjects];
    for (TwitterList * list in someLists)
        [self.lists setObject:list forKey:list.identifier];

    [self updateViewWithNewLists];
    [[ErrorState instance] exitErrorState];
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    self.timelineDisplayMgr.credentials = someCredentials;
}

#pragma mark Private implementation

- (void)fetchListsFromCursor:(NSString *)cursor
{
    outstandingListRequests++;
    [service fetchListsFromCursor:cursor];
    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

- (void)fetchListSubscriptionsFromCursor:(NSString *)cursor
{
    outstandingListSubscriptionRequests++;
    [service fetchListSubscriptionsFromCursor:cursor];
    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

- (void)updateViewWithNewLists
{
    if (outstandingListRequests == 0 &&
        outstandingListSubscriptionRequests == 0) {

        NSLog(@"Showing %d lists and %d subscriptions...", [self.lists count],
            [self.subscriptions count]);

        fetchedInitialLists = YES;

        if (listRequestType == kListRequestTypeLoadMore)
            pagesShown++;
        else
            pagesShown = 1;

        // TODO: enable refresh button

        [listsViewController setLists:self.lists
            subscriptions:self.subscriptions pagesShown:pagesShown];

        

        if ([self.lists count] > 0 || [self.subscriptions count] > 0) {
            [wrapperController setUpdatingState:kConnectedAndNotUpdating];
            [wrapperController setCachedDataAvailable:YES];
        } else {
            NSString * noListsString =
                NSLocalizedString(@"listsdisplaymgr.nolists", @"");
            [wrapperController setNoConnectionText:noListsString];
            [wrapperController setUpdatingState:kDisconnected];
            [wrapperController setCachedDataAvailable:NO];
        }
    }
}

- (void)updateViewForOutstandingQueries
{
    // TODO: disable refresh button
}

@end
