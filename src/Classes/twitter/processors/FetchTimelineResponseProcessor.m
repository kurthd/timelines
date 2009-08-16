//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTimelineResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "UserTweet.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface FetchTimelineResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchTimelineResponseProcessor

@synthesize username, updateId, page, count, credentials, delegate, context;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                credentials:(TwitterCredentials *)someCredentials
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                               page:aPage
                                              count:aCount
                                        credentials:someCredentials
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                   username:(NSString *)aUsername
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                credentials:(TwitterCredentials *)someCredentials
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                           username:aUsername
                                               page:aPage
                                              count:aCount
                                        credentials:someCredentials
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.username = nil;
    self.updateId = nil;
    self.page = nil;
    self.count = nil;
    self.credentials = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
           credentials:(TwitterCredentials *)someCredentials
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    return [self initWithUpdateId:anUpdateId
                         username:nil
                             page:aPage
                            count:aCount
                      credentials:someCredentials
                          context:aContext
                         delegate:aDelegate];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
              username:(NSString *)aUsername
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
           credentials:(TwitterCredentials *)someCredentials
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.updateId = anUpdateId;
        self.page = aPage;
        self.count = aCount;
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

    NSMutableArray * tweets = [NSMutableArray arrayWithCapacity:statuses.count];
    NSMutableSet * uniqueUsers = [NSMutableSet set];
    for (id status in statuses) {
        NSDictionary * userData = [status objectForKey:@"user"];
        // If the user has an empty timeline, there will be one element and none
        // of the required data will be available.
        if (!userData)
            continue;

        NSString * userId = [[userData objectForKey:@"id"] description];
        User * tweetAuthor = [User findOrCreateWithId:userId context:context];

        // only set user data the first time we see it, so we are saving
        // the freshest data
        if (![uniqueUsers containsObject:userId]) {
            [self populateUser:tweetAuthor fromData:userData];
            [uniqueUsers addObject:userId];
        }

        NSDictionary * tweetData = status;

        NSString * tweetId = [[tweetData objectForKey:@"id"] description];
        Tweet * tweet = [Tweet tweetWithId:tweetId context:context];
        if (!tweet) {
            if (self.username)
                tweet = [Tweet createInstance:context];
            else {
                UserTweet * userTweet = [UserTweet createInstance:context];
                userTweet.credentials = self.credentials;
                tweet = userTweet;
            }
        }

        [self populateTweet:tweet fromData:tweetData];
        tweet.user = tweetAuthor;

        [tweets addObject:tweet];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    if (self.username) {
        SEL sel = @selector(timeline:fetchedForUser:sinceUpdateId:page:count:);
        [self invokeSelector:sel withTarget:delegate args:tweets, username,
            updateId, page, count, nil];
    } else {
        SEL sel = @selector(timeline:fetchedSinceUpdateId:page:count:);
        [self invokeSelector:sel withTarget:delegate args:tweets, updateId,
            page, count, nil];
    }

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    if (self.username) {
        SEL sel = @selector(failedToFetchTimelineForUser:sinceUpdateId:page:\
            count:error:);
        [self invokeSelector:sel withTarget:delegate args:username, updateId,
            page, count, error, nil];
    } else {
        SEL sel =
            @selector(failedToFetchTimelineSinceUpdateId:page:count:error:);
        [self invokeSelector:sel withTarget:delegate args:updateId, page, count,
            error, nil];
    }

    return YES;
}

@end
