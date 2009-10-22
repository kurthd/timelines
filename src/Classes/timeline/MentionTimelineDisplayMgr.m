//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#import "MentionTimelineDisplayMgr.h"
#import "ErrorState.h"
#import "NSArray+IterationAdditions.h"
#import "SettingsReader.h"

@interface MentionTimelineDisplayMgr ()

- (void)setUpdatingState;
- (void)fetchMentionsSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages;
- (void)updateBadge;
- (void)updateTweetIndexCache;

- (NetworkAwareViewController *)newTweetDetailsWrapperController;
- (TweetViewController *)newTweetDetailsController;

@property (nonatomic, readonly) TweetViewController * tweetDetailsController;
@property (nonatomic, readonly) NSMutableDictionary * tweetIdToIndexDict;
@property (nonatomic, readonly) NSMutableDictionary * tweetIndexToIdDict;

@property (nonatomic, copy) NSNumber * lastUpdateId;
@property (nonatomic, copy) NSMutableDictionary * mentions;
@property (nonatomic, copy) NSString * activeAcctUsername;
@property (nonatomic, copy) NSString * mentionIdToShow;
@property (nonatomic, retain) TweetInfo * selectedTweet;
@property (nonatomic, retain)
    NetworkAwareViewController * lastTweetDetailsWrapperController;
@property (nonatomic, retain) TweetViewController * lastTweetDetailsController;

@end

@implementation MentionTimelineDisplayMgr

@synthesize lastUpdateId, mentions, activeAcctUsername, mentionIdToShow,
    selectedTweet, lastTweetDetailsWrapperController,
    lastTweetDetailsController;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [tweetDetailsController release];
    [service release];
    [tabBarItem release];
    [composeTweetDisplayMgr release];
    [managedObjectContext release];

    [displayMgrHelper release];

    [lastUpdateId release];
    [mentions release];
    [activeAcctUsername release];
    [selectedTweet release];
    [credentials release];

    [tweetIdToIndexDict release];
    [tweetIndexToIdDict release];
    
    [conversationDisplayMgrs release];

    [lastTweetDetailsWrapperController release];
    [lastTweetDetailsController release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(TwitterService *)aService
    factory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext* )aManagedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry
    tabBarItem:(UITabBarItem *)aTabBarItem
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        timelineController = [aTimelineController retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        managedObjectContext = [aManagedObjectContext retain];
        service = [aService retain];
        tabBarItem = [aTabBarItem retain];

        TwitterService * displayHelperService =
            [[[TwitterService alloc]
            initWithTwitterCredentials:service.credentials
            context:managedObjectContext]
            autorelease];

        displayMgrHelper =
            [[DisplayMgrHelper alloc]
            initWithWrapperController:aWrapperController
            userListDisplayMgrFactor:userListDispMgrFctry
            composeTweetDisplayMgr:aComposeTweetDisplayMgr
            twitterService:service
            timelineFactory:timelineFactory
            managedObjectContext:aManagedObjectContext
            findPeopleBookmarkMgr:findPeopleBookmarkMgr];
        displayHelperService.delegate = displayMgrHelper;

        conversationDisplayMgrs = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark TwitterServiceDelegate implementation

- (void)mentions:(NSArray *)newMentions
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSLog(@"Received mentions (%d)...", [newMentions count]);
    NSLog(@"Mentions update id: %@", updateId);
    NSLog(@"Mentions page: %@", page);

    if ([newMentions count] > 0) {
        NSArray * sortedMentions =
            [[newMentions sortedArrayUsingSelector:@selector(compare:)]
            arrayByReversingContents];
        Tweet * mostRecentTweet = [sortedMentions objectAtIndex:0];
        long long updateIdAsLongLong =
            [mostRecentTweet.identifier longLongValue];
        self.lastUpdateId = [NSNumber numberWithLongLong:updateIdAsLongLong];
    }

    for (Tweet * tweet in newMentions) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [mentions setObject:tweetInfo forKey:tweet.identifier];
    }

    outstandingRequests--;

    if (refreshingMessages) {
        if ([newMentions count] > 0) {
            numNewMentions += [newMentions count];
            [self updateBadge];

            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        }
    } else
        loadMoreNextPage = [page intValue] + 1;

    BOOL scrollToTop = [SettingsReader scrollToTop];
    NSString * scrollId =
        scrollToTop ? [updateId description] : self.mentionIdToShow;
    [timelineController setTweets:[mentions allValues] page:[page intValue]
        visibleTweetId:scrollId];

    [self setUpdatingState];
    [[ErrorState instance] exitErrorState];
}

- (void)failedToFetchMentionsSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"Failed to fetch mentions since %@", updateId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchmessages", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
        retryTarget:self retryAction:@selector(refreshWithLatest)];
    [wrapperController setUpdatingState:kDisconnected];

    outstandingRequests--;
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(TweetInfo *)tweet
{
    // HACK: forces to scroll to top
    [self.tweetDetailsController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    NSLog(@"Mention display manager: selected tweet: %@", tweet);
    self.selectedTweet = tweet;
    
    BOOL tweetByUser = [tweet.user.username isEqual:credentials.username];
    self.tweetDetailsController.navigationItem.rightBarButtonItem.enabled =
        !tweetByUser;
    [self.tweetDetailsController setUsersTweet:tweetByUser];

    NSArray * segmentedControlItems =
        [NSArray arrayWithObjects:[UIImage imageNamed:@"UpButton.png"],
        [UIImage imageNamed:@"DownButton.png"], nil];
    UISegmentedControl * segmentedControl =
        [[[UISegmentedControl alloc] initWithItems:segmentedControlItems]
        autorelease];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    CGRect segmentedControlFrame = segmentedControl.frame;
    segmentedControlFrame.size.width = 88;
    segmentedControl.frame = segmentedControlFrame;
    [segmentedControl addTarget:self action:@selector(handleUpDownButton:)
        forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem * rightBarButtonItem =
        [[[UIBarButtonItem alloc] initWithCustomView:segmentedControl]
        autorelease];
    self.tweetDetailsController.navigationItem.rightBarButtonItem =
        rightBarButtonItem;

    [self.tweetDetailsController hideFavoriteButton:NO];
    self.tweetDetailsController.showsExtendedActions = YES;
    [self.tweetDetailsController displayTweet:tweet
        onNavigationController:wrapperController.navigationController];
    self.tweetDetailsController.allowDeletion =
        [tweet.user.username isEqual:credentials.username];
        
    NSInteger tweetIndex =
        [[self.tweetIdToIndexDict objectForKey:selectedTweet.identifier]
        intValue];
    NSString * titleFormatString =
        NSLocalizedString(@"tweetdetailsview.titleformat", @"");
    self.tweetDetailsController.navigationItem.title =
        [NSString stringWithFormat:titleFormatString, tweetIndex + 1,
        [mentions count]];
    [segmentedControl setEnabled:tweetIndex != 0 forSegmentAtIndex:0];
    [segmentedControl setEnabled:tweetIndex != [mentions count] - 1
        forSegmentAtIndex:1];
}

- (void)loadMoreTweets
{
    NSLog(@"Mention display manager: loading more tweets...");
    [self loadAnotherPageOfMentions];
}

#pragma mark TweetViewControllerDelegate implementation

- (void)showUserInfoForUser:(User *)aUser
{
    [displayMgrHelper showUserInfoForUser:aUser];
}

- (void)showUserInfoForUsername:(NSString *)aUsername
{
    [displayMgrHelper showUserInfoForUsername:aUsername];    
}

- (void)showResultsForSearch:(NSString *)query
{
    [displayMgrHelper showResultsForSearch:query];
}

- (void)setFavorite:(BOOL)favorite
{
    if (favorite)
        NSLog(@"Mention display manager: setting tweet to 'favorite'");
    else
        NSLog(@"Mention display manager: setting tweet to 'not favorite'");
    [[ErrorState instance] exitErrorState];
    [service markTweet:selectedTweet.identifier asFavorite:favorite];
}

- (void)showLocationOnMap:(NSString *)location
{
    [displayMgrHelper showLocationOnMap:location];
}

- (void)showingTweetDetails:(TweetViewController *)tweetController
{
    NSLog(@"Mention display manager: showing tweet details...");
    self.selectedTweet = tweetController.tweet;
    self.lastTweetDetailsController = tweetController;
}

- (void)loadNewTweetWithId:(NSString *)tweetId username:(NSString *)username
{
    NSLog(@"Mention display manager: showing tweet details for tweet %@",
        tweetId);
    
    [service fetchTweet:tweetId];
    [wrapperController.navigationController
        pushViewController:self.newTweetDetailsWrapperController animated:YES];
    [self.lastTweetDetailsWrapperController setCachedDataAvailable:NO];
    [self.lastTweetDetailsWrapperController
        setUpdatingState:kConnectedAndNotUpdating];
}

- (void)reTweetSelected
{
    NSLog(@"Mention display manager: composing retweet");
    NSString * reTweetMessage;
    switch ([SettingsReader retweetFormat]) {
        case kRetweetFormatVia:
            reTweetMessage =
                [NSString stringWithFormat:@"%@ (via @%@)", selectedTweet.text,
                selectedTweet.user.username];
        break;
        case kRetweetFormatRT:
            reTweetMessage =
                [NSString stringWithFormat:@"RT @%@: %@",
                selectedTweet.user.username, selectedTweet.text];
        break;
    }
    
    [composeTweetDisplayMgr composeTweetWithText:reTweetMessage];
}

- (void)replyToTweet
{
    NSLog(@"Mention display manager: reply to tweet selected");
    [composeTweetDisplayMgr
        composeReplyToTweet:selectedTweet.identifier
        fromUser:selectedTweet.user.username];
}

- (void)loadConversationFromTweetId:(NSString *)tweetId
{
    UINavigationController * navController =
        wrapperController.navigationController;
    
    ConversationDisplayMgr * mgr =
        [[ConversationDisplayMgr alloc]
        initWithTwitterService:[service clone]
        context:managedObjectContext];
    [conversationDisplayMgrs addObject:mgr];
    [mgr release];
    
    mgr.delegate = self;
    [mgr displayConversationFrom:tweetId navigationController:navController];
}

- (void)deleteTweet:(NSString *)tweetId
{
    NSLog(@"Removing mention with id %@", tweetId);
    [mentions removeObjectForKey:tweetId];
    [timelineController performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:0.5];

    // Delete the tweet from Twitter after a longer delay than used for the
    // deleteTweet: method above. The Tweet object is deleted when we receive
    // confirmation from Twitter that they've deleted it. If this happens before
    // deleteTweet: executes, the method will crash because the Tweet object is
    // expected to be alive.
    [service performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:1.0];

    [self updateTweetIndexCache];
}

#pragma mark ConversationDisplayMgrDelegate implementation

- (void)displayTweetFromConversation:(TweetInfo *)tweet
{
    TweetViewController * controller = [self newTweetDetailsController];

    self.selectedTweet = tweet;

    [controller hideFavoriteButton:NO];
    controller.showsExtendedActions = YES;
    [controller displayTweet:tweet
        onNavigationController:wrapperController.navigationController];
}

#pragma mark Public interface implementation

- (void)refreshWithLatest
{
    [[ErrorState instance] exitErrorState];
    [self updateMentionsSinceLastUpdateIds];
}

- (void)updateMentionsSinceLastUpdateIds
{
    NSLog(@"Updating mentions since update id %@...", self.lastUpdateId);
    if (self.lastUpdateId) {
        refreshingMessages = YES;
        [self fetchMentionsSinceId:self.lastUpdateId page:nil numMessages:nil];
        [self setUpdatingState];
    } else
        [self updateWithABunchOfRecentMentions];
}

- (void)updateWithABunchOfRecentMentions
{
    NSLog(@"Updating with a bunch of mentions...");
    refreshingMessages = NO;
    NSNumber * count = [NSNumber numberWithInteger:200];
    [self fetchMentionsSinceId:nil page:[NSNumber numberWithInt:1]
        numMessages:count];
    [self setUpdatingState];
}

- (void)loadAnotherPageOfMentions
{
    NSLog(@"Loading more messages (page %d)...", loadMoreNextPage);
    refreshingMessages = NO;
    NSNumber * count = [NSNumber numberWithInteger:200];
    [self fetchMentionsSinceId:nil 
        page:[NSNumber numberWithInt:loadMoreNextPage] numMessages:count];
    [self setUpdatingState];
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Mention display manager: setting credentials to '%@'",
        someCredentials.username);

    [someCredentials retain];
    [credentials autorelease];
    credentials = someCredentials;

    [service setCredentials:someCredentials];

    self.activeAcctUsername = someCredentials.username;
    [displayMgrHelper setCredentials:someCredentials];

    [wrapperController.navigationController popToRootViewControllerAnimated:NO];
}

- (void)clearState
{
    [self.mentions removeAllObjects];
    alreadyBeenDisplayedAfterCredentialChange = NO;
    loadMoreNextPage = 1;
    refreshingMessages = NO;
    [conversationDisplayMgrs removeAllObjects];
}

#pragma mark Private interface implementation

- (TweetViewController *)tweetDetailsController
{
    if (!tweetDetailsController) {
        tweetDetailsController =
            [[TweetViewController alloc]
            initWithNibName:@"TweetView" bundle:nil];

        UIBarButtonItem * replyButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
            action:@selector(presentTweetActions)]
            autorelease];
        [tweetDetailsController.navigationItem
            setRightBarButtonItem:replyButton];

        NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
        tweetDetailsController.navigationItem.title = title;
        tweetDetailsController.navigationItem.backBarButtonItem =
            [[[UIBarButtonItem alloc]
            initWithTitle:title style:UIBarButtonItemStyleBordered target:nil
            action:nil]
            autorelease];
            
        tweetDetailsController.delegate = self;
    }

    return tweetDetailsController;
}

- (NSMutableDictionary *)tweetIdToIndexDict
{
    if (!tweetIdToIndexDict)
        tweetIdToIndexDict = [[NSMutableDictionary dictionary] retain];

    return tweetIdToIndexDict;
}

- (NSMutableDictionary *)tweetIndexToIdDict
{
    if (!tweetIndexToIdDict)
        tweetIndexToIdDict = [[NSMutableDictionary dictionary] retain];

    return tweetIndexToIdDict;
}

- (NetworkAwareViewController *)newTweetDetailsWrapperController
{
    TweetViewController * tempTweetDetailsController =
        self.newTweetDetailsController;
    NetworkAwareViewController * tweetDetailsWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:tempTweetDetailsController]
        autorelease];
    tempTweetDetailsController.realParentViewController =
        tweetDetailsWrapperController;

    UIBarButtonItem * replyButton =
        [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
        action:@selector(presentActionsForCurrentTweetDetailsUser)]
        autorelease];
    [tweetDetailsWrapperController.navigationItem
        setRightBarButtonItem:replyButton];

    NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
    tweetDetailsWrapperController.navigationItem.title = title;

    return self.lastTweetDetailsWrapperController =
        tweetDetailsWrapperController;
}

- (TweetViewController *)newTweetDetailsController
{
    TweetViewController * newTweetViewController =
        [[TweetViewController alloc] initWithNibName:@"TweetView" bundle:nil];
    newTweetViewController.delegate = self;
    self.lastTweetDetailsController = newTweetViewController;
    [newTweetViewController release];

    return newTweetViewController;
}

- (void)setUpdatingState
{
    if (outstandingRequests == 0)
        [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    else
        [wrapperController setUpdatingState:kConnectedAndUpdating];
}

- (void)fetchMentionsSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages
{
    if (outstandingRequests == 0) { // only one at a time
        outstandingRequests++;
        [service fetchDirectMessagesSinceId:updateId page:page
            count:numMessages];
    }
}

- (void)updateBadge
{
    tabBarItem.badgeValue =
        numNewMentions > 0 ?
        [NSString stringWithFormat:@"%d", numNewMentions] : nil;
}

- (void)updateTweetIndexCache
{
    [self.tweetIdToIndexDict removeAllObjects];
    [self.tweetIndexToIdDict removeAllObjects];
    NSArray * sortedTweets =
        [[[mentions allValues] sortedArrayUsingSelector:@selector(compare:)]
        arrayByReversingContents];
    for (NSInteger i = 0; i < [sortedTweets count]; i++) {
        TweetInfo * tweetInfo = [sortedTweets objectAtIndex:i];
        [self.tweetIdToIndexDict setObject:[NSNumber numberWithInt:i]
            forKey:tweetInfo.identifier];
        [self.tweetIndexToIdDict setObject:tweetInfo.identifier
            forKey:[NSNumber numberWithInt:i]];
    }
}

@end
