//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitterService.h"
#import "MGTwitterEngine.h"
#import "ResponseProcessors.h"

@interface TwitterService ()

- (void)request:(id)requestId isHandledBy:(ResponseProcessor *)processor;
- (ResponseProcessor *)processorForRequest:(id)requestId;
- (void)cleanUpRequest:(id)requestId;
- (void)request:(id)rid succeededWithResponse:(id)response;
- (void)request:(id)rid failed:(NSError *)error;

@end

@implementation TwitterService

@synthesize delegate, credentials;

- (void)dealloc
{
    self.delegate = nil;

    [pendingRequests release];

    [credentials release];
    [twitter release];

    [context release];

    [super dealloc];
}

- (id)initWithTwitterCredentials:(TwitterCredentials *)someCredentials
                         context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        pendingRequests = [[NSMutableDictionary alloc] init];

        twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
        [twitter setUsesSecureConnection:YES];

        self.credentials = someCredentials;
        
        context = [aContext retain];
    }

    return self;
}

- (void)checkCredentials
{
    ResponseProcessor * processor =
        [CheckCredentialsResponseProcessor
        processorWithCredentials:credentials
                        delegate:delegate];

    NSString * requestId = [twitter checkUserCredentials];

    [self request:requestId isHandledBy:processor];
}

#pragma mark Sending tweets

// is 'tweet' a verb or a noun?
- (void)sendTweet:(NSString *)tweet
{
    ResponseProcessor * processor =
        [SendTweetResponseProcessor processorWithTweet:tweet
                                               context:context
                                              delegate:delegate];

    NSString * requestId = [twitter sendUpdate:tweet];

    [self request:requestId isHandledBy:processor];
}

- (void)sendTweet:(NSString *)tweet inReplyTo:(NSNumber *)referenceId
{
}

#pragma mark Timelines

- (void)fetchTimelineSinceUpdateId:(NSNumber *)updateId
                              page:(NSNumber *)page
                             count:(NSNumber *)count
{
    ResponseProcessor * processor =
        [FetchTimelineResponseProcessor processorWithUpdateId:updateId
                                                         page:page
                                                        count:count
                                                      context:context
                                                     delegate:delegate];

    NSString * requestId =
        [twitter getFollowedTimelineFor:credentials.username
                                sinceID:[updateId integerValue]
                         startingAtPage:[page integerValue]
                                  count:[count integerValue]];

    [self request:requestId isHandledBy:processor];
}

- (void)fetchTimelineForUser:(NSString *)user
               sinceUpdateId:(NSNumber *)updateId
                        page:(NSNumber *)page
                       count:(NSNumber *)count
{
    ResponseProcessor * processor =
        [FetchTimelineResponseProcessor processorWithUpdateId:updateId
                                                     username:user
                                                         page:page
                                                        count:count
                                                      context:context
                                                     delegate:delegate];

    NSString * requestId =
        [twitter getUserTimelineFor:user
                            sinceID:[updateId integerValue]
                     startingAtPage:[page integerValue]
                              count:[count integerValue]];

    [self request:requestId isHandledBy:processor];
}

#pragma mark Mentions

- (void)fetchMentionsSinceUpdateId:(NSNumber *)updateId
                              page:(NSNumber *)page
                             count:(NSNumber *)count
{
    ResponseProcessor * processor =
        [FetchMentionsResponseProcessor processorWithUpdateId:updateId
                                                         page:page
                                                        count:count
                                                      context:context
                                                     delegate:delegate];

    NSString * requestId =
        [twitter getMentionsSinceID:[updateId integerValue]
                               page:[page integerValue]
                              count:[count integerValue]];

    [self request:requestId isHandledBy:processor];
}

#pragma mark Direct messages

- (void)fetchDirectMessagesSinceId:(NSNumber *)updateId page:(NSNumber *)page
{
    ResponseProcessor * processor =
        [FetchDirectMessagesResponseProcessor processorWithUpdateId:updateId
                                                               page:page
                                                            context:context
                                                           delegate:delegate];

    NSString * requestId =
        [twitter getDirectMessagesSinceID:[updateId integerValue]
                           startingAtPage:[page integerValue]];

    [self request:requestId isHandledBy:processor];
}

- (void)sendDirectMessage:(NSString *)message to:(NSString *)username
{
    ResponseProcessor * processor =
        [SendDirectMessageResponseProcessor processorWithTweet:message
                                                      username:username
                                                       context:context
                                                      delegate:delegate];

    NSString * requestId = [twitter sendDirectMessage:message to:username];

    [self request:requestId isHandledBy:processor];
}

#pragma mark Favorites

- (void)fetchFavoritesForUser:(NSString *)user page:(NSNumber *)page
{
    ResponseProcessor * processor =
        [FetchFavoritesForUserResponseProcessor processorWithUsername:user
                                                                 page:page
                                                              context:context
                                                             delegate:delegate];

    NSString * requestId =
        [twitter getFavoriteUpdatesFor:user startingAtPage:[page integerValue]];

    [self request:requestId isHandledBy:processor];
}

- (void)markTweet:(NSString *)tweetId asFavorite:(BOOL)favorite
{
    ResponseProcessor * processor =
        [MarkFavoriteResponseProcessor processorWithTweetId:tweetId
                                                   favorite:favorite
                                                    context:context
                                                   delegate:delegate];

    NSString * requestId = [twitter markUpdate:tweetId asFavorite:favorite];

    [self request:requestId isHandledBy:processor];
}

#pragma mark User info

- (void)fetchUserInfoForUsername:(NSString *)username
{
    ResponseProcessor * processor =
        [FetchUserInfoResponseProcessor processorWithUsername:username
                                                      context:context
                                                     delegate:delegate];

    NSString * requestId = [twitter getUserInformationFor:username];

    [self request:requestId isHandledBy:processor];
}

- (void)followUser:(NSString *)username
{
    ResponseProcessor * processor =
        [FollowUserResponseProcessor processorWithUsername:username
                                                 following:YES
                                                   context:context
                                                  delegate:delegate];

    NSString * requestId = [twitter enableUpdatesFor:username];

    [self request:requestId isHandledBy:processor];
}

- (void)stopFollowingUser:(NSString *)username
{
    ResponseProcessor * processor =
        [FollowUserResponseProcessor processorWithUsername:username
                                                 following:NO
                                                   context:context
                                                  delegate:delegate];

    NSString * requestId = [twitter disableUpdatesFor:username];

    [self request:requestId isHandledBy:processor];
}

#pragma mark Social graph

- (void)fetchFriendsForUser:(NSString *)user page:(NSNumber *)page
{
    ResponseProcessor * processor =
        [FetchFriendsForUserResponseProcessor processorWithUsername:user
                                                               page:page
                                                            context:context
                                                           delegate:delegate];

    NSString * requestId =
        [twitter getRecentlyUpdatedFriendsFor:user
                               startingAtPage:[page integerValue]];

    [self request:requestId isHandledBy:processor];
}

- (void)fetchFollowersForUser:(NSString *)user page:(NSNumber *)page
{
    ResponseProcessor * processor =
        [FetchFollowersForUserResponseProcessor processorWithUsername:user
                                                                 page:page
                                                              context:context
                                                             delegate:delegate];

    NSString * requestId =
        [twitter getFollowersFor:user startingAtPage:[page integerValue]];

    [self request:requestId isHandledBy:processor];
}

#pragma mark MGTwitterEngineDelegate implementation

- (void)requestSucceeded:(NSString *)requestId
{
    NSLog(@"Request '%@' succeeded.", requestId);
    [self request:requestId succeededWithResponse:nil];
}

- (void)requestFailed:(NSString *)requestId withError:(NSError *)error
{
    NSLog(@"Request '%@' failed; error: '%@'.", requestId, error);
    [self request:requestId failed:error];
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)requestId
{
    NSLog(@"Statuses recieved for request '%@': %@", requestId, statuses);
    [self request:requestId succeededWithResponse:statuses];
    [self cleanUpRequest:requestId];
}

- (void)directMessagesReceived:(NSArray *)messages
                    forRequest:(NSString *)requestId
{
    NSLog(@"Direct messages recieved for request '%@': %@", requestId,
        messages);
    [self request:requestId succeededWithResponse:messages];
    [self cleanUpRequest:requestId];
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)requestId
{
    NSLog(@"User info received for request '%@': %@", requestId, userInfo);
    [self request:requestId succeededWithResponse:userInfo];
    [self cleanUpRequest:requestId];
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
    NSLog(@"Misc. info received for request '%@': %@", identifier, miscInfo);
}

- (void)imageReceived:(UIImage *)image forRequest:(NSString *)identifier
{
    NSLog(@"Image received for request '%@': %@", identifier, image);
}

#pragma mark Request processing helpers

- (void)request:(id)requestId isHandledBy:(ResponseProcessor *)processor
{
    [pendingRequests setObject:processor forKey:requestId];
}

- (ResponseProcessor *)processorForRequest:(id)rid
{
    ResponseProcessor * processor = [pendingRequests objectForKey:rid];
    NSAssert1(processor, @"Failed to find processor for request: '%@'.", rid);

    return processor;
}

- (void)cleanUpRequest:(id)requestId
{
    [pendingRequests removeObjectForKey:requestId];
}

- (void)request:(id)rid succeededWithResponse:(id)response
{
    [[self processorForRequest:rid] process:response];
    //[self cleanUpRequest:rid];
}

- (void)request:(id)rid failed:(NSError *)error
{
    [[self processorForRequest:rid] processError:error];
    //[self cleanUpRequest:rid];
}

#pragma mark Accessors

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    if (credentials != someCredentials) {
        [credentials release];
        credentials = [someCredentials retain];

        [twitter setUsername:credentials.username
                    password:credentials.password];
    }
}

@end
