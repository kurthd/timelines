//
//  MGTwitterEngine.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#import "MGTwitterEngineDelegate.h"
#import "MGTwitterParserDelegate.h"

#import <CoreLocation/CoreLocation.h>  // for CLLocationCoordinate2D

@interface MGTwitterEngine : NSObject <MGTwitterParserDelegate> {
    __weak NSObject <MGTwitterEngineDelegate> *_delegate;
    NSString *_username;
    NSString *_password;
    NSMutableDictionary *_connections;   // MGTwitterHTTPURLConnection objects
    NSString *_clientName;
    NSString *_clientVersion;
    NSString *_clientURL;
    NSString *_clientSourceToken;
	NSString *_APIDomain;
    NSString *_APIVersion;
#if JSON_AVAILABLE || YAJL_AVAILABLE
	NSString *_searchDomain;
#endif
    BOOL _secureConnection;
	BOOL _clearsCookies;
#if YAJL_AVAILABLE
	MGTwitterEngineDeliveryOptions _deliveryOptions;
#endif
}

#pragma mark Class management

// Constructors
+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)delegate;
- (MGTwitterEngine *)initWithDelegate:(NSObject *)delegate;

// Configuration and Accessors
+ (NSString *)version; // returns the version of MGTwitterEngine
- (NSString *)username;
- (NSString *)password;
- (void)setUsername:(NSString *)username password:(NSString *)password;
- (NSString *)clientName; // see README.txt for info on clientName/Version/URL/SourceToken
- (NSString *)clientVersion;
- (NSString *)clientURL;
- (NSString *)clientSourceToken;
- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
- (NSString *)APIDomain;
- (void)setAPIDomain:(NSString *)domain;
#if JSON_AVAILABLE || YAJL_AVAILABLE
- (NSString *)searchDomain;
- (void)setSearchDomain:(NSString *)domain;
#endif
- (BOOL)usesSecureConnection; // YES = uses HTTPS, default is YES
- (void)setUsesSecureConnection:(BOOL)flag;
- (BOOL)clearsCookies; // YES = deletes twitter.com cookies when setting username/password, default is NO (see README.txt)
- (void)setClearsCookies:(BOOL)flag;
#if YAJL_AVAILABLE
- (MGTwitterEngineDeliveryOptions)deliveryOptions;
- (void)setDeliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;
#endif

// Connection methods
- (int)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnection:(NSString *)identifier;
- (void)closeAllConnections;

// Utility methods
/// Note: the -getImageAtURL: method works for any image URL, not just Twitter images.
// It does not require authentication, and is provided here for convenience.
// As with the Twitter API methods below, it returns a unique connection identifier.
// Retrieved images are sent to the delegate via the -imageReceived:forRequest: method.
- (NSString *)getImageAtURL:(NSString *)urlString;

#pragma mark REST API methods

// ======================================================================================================
// Twitter REST API methods
// See documentation at: http://apiwiki.twitter.com/REST+API+Documentation
// All methods below return a unique connection identifier.
// ======================================================================================================

// Status methods - http://apiwiki.twitter.com/REST+API+Documentation#StatusMethods

- (NSString *)getPublicTimelineSinceID:(int)updateID; // statuses/public_timeline

- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum; // statuses/friends_timeline
- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline
- (NSString *)getFollowedTimelineFor:(NSString *)username sinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)count; // statuses/friends_timeline

- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date count:(int)numUpdates; // statuses/user_timeline
- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)numUpdates; // statuses/user_timeline
- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)numUpdates; // statuses/user_timeline

- (NSString *)getUpdate:(NSString *)updateID; // statuses/show
- (NSString *)sendUpdate:(NSString *)status; // statuses/update
- (NSString *)sendUpdate:(NSString *)status coordinate:(CLLocationCoordinate2D)coord;
- (NSString *)sendUpdate:(NSString *)status inReplyTo:(NSString *)updateID; // statuses/update
- (NSString *)sendUpdate:(NSString *)status coordinate:(CLLocationCoordinate2D)coord inReplyTo:(NSString *)updateID;

- (NSString *)sendRetweet:(NSString *)updateID;  // statuses/retweet

- (NSString *)getRepliesStartingAtPage:(int)pageNum; // statuses/replies
- (NSString *)getRepliesSince:(NSDate *)date startingAtPage:(int)pageNum count:(int)count; // statuses/replies
- (NSString *)getRepliesSinceID:(int)updateID startingAtPage:(int)pageNum count:(int)count; // statuses/replies

- (NSString *)deleteUpdate:(NSString *)updateID; // statuses/destroy

// Getting mentions
- (NSString *)getMentionsSinceID:(NSString *)updateID page:(int)page count:(int)count;

- (NSString *)getRetweetsSinceID:(NSString *)updateID page:(int)pageNum count:(int)count;

- (NSString *)getFeaturedUsers; // statuses/features (undocumented, returns invalid JSON data)


// User methods - http://apiwiki.twitter.com/REST+API+Documentation#UserMethods

- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)pageNum; // DEPRECATED -- statuses/friends
- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username cursor:(NSString *)cursor; // statuses/friends
- (NSString *)getFollowersFor:(NSString *)username startingAtPage:(int)pageNum;  // DEPRECATED
- (NSString *)getFollowersFor:(NSString *)username cursor:(NSString *)cursor;
- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag; // statuses/followers

- (NSString *)getUserInformationFor:(NSString *)usernameOrID; // users/show
- (NSString *)getUserInformationForEmail:(NSString *)email; // users/show


// Direct Message methods - http://apiwiki.twitter.com/REST+API+Documentation#DirectMessageMethods

- (NSString *)getDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum; // direct_messages
- (NSString *)getDirectMessagesSinceID:(int)updateID startingAtPage:(int)pageNum; // direct_messages
- (NSString *)getDirectMessagesSinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)count; // direct_messages

- (NSString *)getSentDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum; // direct_messages/sent
- (NSString *)getSentDirectMessagesSinceID:(int)updateID startingAtPage:(int)pageNum; // direct_messages/sent
- (NSString *)getSentDirectMessagesSinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)count; // direct_messages/sent

- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username; // direct_messages/new
- (NSString *)deleteDirectMessage:(NSString *)updateID;// direct_messages/destroy

- (NSString *)getDirectMessage:(NSString *)updateID;  // direct_messages/show


// List methods - http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-lists
- (NSString *)getListsFor:(NSString *)username cursor:(NSString *)cursor;
- (NSString *)getListSubscriptionsFor:(NSString *)username cursor:(NSString *)cursor;

- (NSString *)fetchStatusesForListWithId:(NSNumber *)listId ownedByUser:(NSString *)username sinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page count:(NSNumber *)count;


// Friendship methods - http://apiwiki.twitter.com/REST+API+Documentation#FriendshipMethods

- (NSString *)enableUpdatesFor:(NSString *)username; // friendships/create (follow username)
- (NSString *)disableUpdatesFor:(NSString *)username; // friendships/destroy (unfollow username)
- (NSString *)isUser:(NSString *)username1 receivingUpdatesFor:(NSString *)username2; // friendships/exists (test if username1 follows username2)


// Account methods - http://apiwiki.twitter.com/REST+API+Documentation#AccountMethods

- (NSString *)checkUserCredentials; // account/verify_credentials
- (NSString *)endUserSession; // account/end_session

- (NSString *)setLocation:(NSString *)location; // account/update_location (deprecated, use account/update_profile instead)

- (NSString *)setNotificationsDeliveryMethod:(NSString *)method; // account/update_delivery_device

// TODO: Add: account/update_profile_colors
// TODO: Add: account/update_profile_image
// TODO: Add: account/update_profile_background_image

- (NSString *)getRateLimitStatus; // account/rate_limit_status

// TODO: Add: account/update_profile

// - (NSString *)getUserUpdatesArchiveStartingAtPage:(int)pageNum; // account/archive (removed, use /statuses/user_timeline instead)


// Favorite methods - http://apiwiki.twitter.com/REST+API+Documentation#FavoriteMethods

- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)pageNum; // favorites

- (NSString *)markUpdate:(NSString *)updateID asFavorite:(BOOL)flag; // favorites/create, favorites/destroy


// Notification methods - http://apiwiki.twitter.com/REST+API+Documentation#NotificationMethods

- (NSString *)enableNotificationsFor:(NSString *)username; // notifications/follow
- (NSString *)disableNotificationsFor:(NSString *)username; // notifications/leave


// Block methods - http://apiwiki.twitter.com/REST+API+Documentation#BlockMethods

- (NSString *)block:(NSString *)username; // blocks/create
- (NSString *)unblock:(NSString *)username; // blocks/destroy
- (NSString *)isBlocking:(NSString *)username;  // blocks/exists


// Help methods - http://apiwiki.twitter.com/REST+API+Documentation#HelpMethods

- (NSString *)testService; // help/test

- (NSString *)getDowntimeSchedule; // help/downtime_schedule (undocumented)


#pragma mark Search API methods

// ======================================================================================================
// Twitter Search API methods
// See documentation at: http://apiwiki.twitter.com/Search+API+Documentation
// All methods below return a unique connection identifier.
// ======================================================================================================

#if JSON_AVAILABLE || YAJL_AVAILABLE

// Search method - http://apiwiki.twitter.com/Search+API+Documentation#Search

- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(NSString *)updateID maxID:(NSString *)maxID startingAtPage:(int)pageNum count:(int)count; // search

// nearby search
- (NSString *)getSearchResultsForQuery:(NSString *)query
                               sinceID:(NSString *)updateID
                                 maxID:(NSString *)maxID
                        startingAtPage:(int)pageNum
                                 count:(int)count
                              latitude:(float)latitude
                             longitude:(float)longitude
                                radius:(int)radius
                       radiusIsInMiles:(BOOL)radiusIsInMiles;

// Trends method - http://apiwiki.twitter.com/Search+API+Documentation#Trends

- (NSString *)getTrends; // trends
- (NSString *)getCurrentTrends;
- (NSString *)getDailyTrends;
- (NSString *)getWeeklyTrends;

// People search - http://apiwiki.twitter.com/Twitter-REST-API-Method:-users-search

- (NSString *)getUserSearchResultsForQuery:(NSString *)query count:(int)count startingAtPage:(int)pageNum;

#endif

+ (BOOL)useVersionedApi;

@end

@interface NSError (MGTwitterEngineAdditions)

+ (NSString *)twitterApiErrorDomain;

@end