//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "Tweet.h"
#import "TweetInfo.h"

@interface SearchDisplayMgr ()

@property (nonatomic, retain) NetworkAwareViewController *
    networkAwareViewController;

@property (nonatomic, retain) TwitterService * service;

@property (nonatomic, copy) NSArray * searchResults;
@property (nonatomic, copy) NSString * queryString;
@property (nonatomic, copy) NSString * queryTitle;
@property (nonatomic, copy) NSNumber * updateId;

@end

@implementation SearchDisplayMgr

@synthesize networkAwareViewController;
@synthesize service;
@synthesize searchResults, queryString, queryTitle, updateId;
@synthesize dataSourceDelegate;

#pragma mark Initialization

- (id)initWithTwitterService:(TwitterService *)aService
{
    if (self = [super init]) {
        self.service = aService;
        self.service.delegate = self;
    }

    return self;
}

- (void)dealloc
{
    self.networkAwareViewController = nil;
    self.service = nil;
    self.searchResults = nil;
    self.queryString = nil;
    self.queryTitle = nil;
    self.updateId = nil;
    [super dealloc];
}

#pragma mark Display search results

- (void)displaySearchResults:(NSString *)aQueryString
                   withTitle:(NSString *)aTitle
{
    self.searchResults = nil;
    self.queryString = aQueryString;
    self.queryTitle = aTitle;
}

- (void)clearDisplay
{
    self.searchResults = nil;
    self.queryString = nil;
    self.queryTitle = nil;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)anUpdateId page:(NSNumber *)page
{
    if (self.queryString) {
        self.updateId = anUpdateId;
        [service searchFor:self.queryString page:page];
    }
}

- (TwitterCredentials *)credentials
{
    return service.credentials;
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [service setCredentials:someCredentials];
}

- (void)fetchUserInfoForUsername:(NSString *)username
{
    [service fetchUserInfoForUsername:username];
}

- (void)fetchFriendsForUser:(NSString *)user page:(NSNumber *)page
{
    [service fetchFriendsForUser:user page:page];
}

- (void)fetchFollowersForUser:(NSString *)user page:(NSNumber *)page
{
    [service fetchFollowersForUser:user page:page];
}

- (void)isUser:(NSString *)user following:(NSString *)followee
{
    [service isUser:user following:followee];
}

- (void)followUser:(NSString *)username
{
    [service followUser:username];
}

- (void)stopFollowingUser:(NSString *)username
{
    [service stopFollowingUser:username];
}

- (void)markTweet:(NSString *)tweetId asFavorite:(BOOL)favorite
{
    [service markTweet:tweetId asFavorite:favorite];
}

- (void)fetchTweet:(NSString *)tweetId
{
    [service fetchTweet:tweetId];
}

#pragma mark TwitterServiceDelegate

- (void)searchResultsReceived:(NSArray *)newSearchResults
                     forQuery:(NSString *)query
                         page:(NSNumber *)page
{
    self.searchResults = newSearchResults;
    if ([query isEqualToString:self.queryString]) {
        NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
        for (Tweet * tweet in searchResults) {
            TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
            [tweetInfoTimeline addObject:tweetInfo];
        }
        [self.dataSourceDelegate timeline:tweetInfoTimeline
                     fetchedSinceUpdateId:self.updateId
                                     page:page];
    }
}

- (void)failedToFetchSearchResultsForQuery:(NSString *)query
                                      page:(NSNumber *)page
                                     error:(NSError *)error
{
    if ([query isEqualToString:self.queryString])
        [self.dataSourceDelegate failedToFetchTimelineSinceUpdateId:updateId
                                                               page:page
                                                              error:error];
}

- (void)timeline:(NSArray *)timeline fetchedForUser:(NSString *)user
    sinceUpdateId:(NSNumber *)theUpdateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
    for (Tweet * tweet in timeline) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [tweetInfoTimeline addObject:tweetInfo];
    }
    [self.dataSourceDelegate timeline:tweetInfoTimeline
                 fetchedSinceUpdateId:theUpdateId
                                 page:page];
}

- (void)failedToFetchTimelineForUser:(NSString *)user
    sinceUpdateId:(NSNumber *)theUpdateId page:(NSNumber *)page
    count:(NSNumber *)count error:(NSError *)error
{
    [self.dataSourceDelegate failedToFetchTimelineSinceUpdateId:theUpdateId
                                                           page:page
                                                          error:error];
}

- (void)userInfo:(User *)aUser fetchedForUsername:(NSString *)aUsername
{
    [self.dataSourceDelegate userInfo:aUser fetchedForUsername:aUsername];
}

- (void)failedToFetchUserInfoForUsername:(NSString *)aUsername
                                   error:(NSError *)error
{
    [self.dataSourceDelegate failedToFetchUserInfoForUsername:aUsername
                                                        error:error];
}

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)aUsername
    page:(NSNumber *)page
{
    [self.dataSourceDelegate friends:friends
                  fetchedForUsername:aUsername
                                page:page];
}

- (void)failedToFetchFriendsForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    [self.dataSourceDelegate failedToFetchFriendsForUsername:aUsername
                                                        page:page
                                                       error:error];
}

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)aUsername
            page:(NSNumber *)page
{
    [self.dataSourceDelegate followers:friends
                    fetchedForUsername:aUsername
                                  page:page];
}

- (void)failedToFetchFollowersForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    [self.dataSourceDelegate failedToFetchFollowersForUsername:aUsername
                                                          page:page
                                                         error:error];
}

- (void)startedFollowingUsername:(NSString *)aUsername
{
    [self.dataSourceDelegate startedFollowingUsername:aUsername];
}

- (void)failedToStartFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    [self.dataSourceDelegate failedToStartFollowingUsername:aUsername];
}

- (void)stoppedFollowingUsername:(NSString *)aUsername
{
    [self.dataSourceDelegate stoppedFollowingUsername:aUsername];
}

- (void)failedToStopFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    [self.dataSourceDelegate failedToStopFollowingUsername:aUsername];
}

- (void)user:(NSString *)aUsername isFollowing:(NSString *)followee
{
    [self.dataSourceDelegate user:aUsername isFollowing:followee];
}

- (void)user:(NSString *)aUsername isNotFollowing:(NSString *)followee
{
    [self.dataSourceDelegate user:aUsername isNotFollowing:followee];
}

- (void)failedToQueryIfUser:(NSString *)aUsername
    isFollowing:(NSString *)followee error:(NSError *)error
{
    [self.dataSourceDelegate failedToQueryIfUser:aUsername
                                     isFollowing:followee error:error];
}

- (void)fetchedTweet:(Tweet *)tweet withId:(NSString *)tweetId
{
    [self.dataSourceDelegate fetchedTweet:tweet withId:tweetId];
}

- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error
{
    [self.dataSourceDelegate failedToFetchTweetWithId:tweetId error:error];
}
 
@end
