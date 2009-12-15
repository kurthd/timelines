//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SendTweetResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "UserTweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TwitbitShared.h"

@interface SendTweetResponseProcessor ()

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSNumber * referenceId;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

// The designated initializer
- (id)initWithTweet:(NSString *)someText
      coordinatePtr:(CLLocationCoordinate2D *)aCoordinate
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate;

@end

@implementation SendTweetResponseProcessor

@synthesize text, referenceId, credentials, context, delegate;

+ (id)processorWithTweet:(NSString *)someText
             referenceId:(NSNumber *)aReferenceId
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[self alloc] initWithTweet:someText
                             referenceId:aReferenceId
                             credentials:someCredentials
                                 context:aContext
                                delegate:aDelegate];
    return [obj autorelease];
}

+ (id)processorWithTweet:(NSString *)someText
              coordinate:(CLLocationCoordinate2D)aCoordinate
             referenceId:(NSNumber *)aReferenceId
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[self alloc] initWithTweet:someText
                              coordinate:aCoordinate
                             referenceId:aReferenceId
                             credentials:someCredentials
                                 context:aContext
                                delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.text = nil;

    if (coordinate)
        free(coordinate);

    self.referenceId = nil;
    self.credentials = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTweet:(NSString *)someText
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate
{
    return [self initWithTweet:someText
                 coordinatePtr:NULL
                   referenceId:aReferenceId
                   credentials:someCredentials
                       context:aContext
                      delegate:aDelegate];
}

- (id)initWithTweet:(NSString *)someText
         coordinate:(CLLocationCoordinate2D)aCoordinate
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate
{
    return [self initWithTweet:someText
                 coordinatePtr:&aCoordinate
                   referenceId:aReferenceId
                   credentials:someCredentials
                       context:aContext
                      delegate:aDelegate];
}

- (id)initWithTweet:(NSString *)someText
      coordinatePtr:(CLLocationCoordinate2D *)aCoordinate
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.text = someText;

        if (aCoordinate) {
            coordinate = (CLLocationCoordinate2D *)
                malloc(sizeof(CLLocationCoordinate2D));
            memcpy(coordinate, &aCoordinate, sizeof(CLLocationCoordinate2D));
        } else
            coordinate = NULL;

        self.referenceId = aReferenceId;
        self.credentials = someCredentials;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}


- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSAssert1(statuses.count == 1, @"Expected 1 status in response; received "
        "%d.", statuses.count);

    NSDictionary * status = [statuses lastObject];

    NSDictionary * userData = [status objectForKey:@"user"];
    NSNumber * userId = [[userData objectForKey:@"id"] twitterIdentifierValue];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:userData];

    NSDictionary * tweetData = status;

    NSNumber * tweetId =
        [[tweetData objectForKey:@"id"] twitterIdentifierValue];
    UserTweet * tweet = [UserTweet tweetWithId:tweetId context:context];
    if (!tweet)
        tweet = [UserTweet createInstance:context];

    [self populateTweet:tweet fromData:tweetData
        isSearchResult:NO context:context];
    tweet.user = user;
    tweet.credentials = self.credentials;

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    if (referenceId) {
        SEL sel = @selector(tweet:sentInReplyTo:);
        if ([delegate respondsToSelector:sel])
            [delegate tweet:tweet sentInReplyTo:referenceId];
    } else {
        SEL sel = @selector(tweetSentSuccessfully:);
        if ([delegate respondsToSelector:sel])
            [delegate tweetSentSuccessfully:tweet];
    }

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    if (referenceId) {
        SEL sel = @selector(failedToReplyToTweet:withText:error:);
        if ([delegate respondsToSelector:sel])
            [delegate
                failedToReplyToTweet:referenceId withText:text error:error];
    } else {
        SEL sel = @selector(failedToSendTweet:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToSendTweet:text error:error];
    }

    return YES;
}

@end
