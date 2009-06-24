//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTimelineResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface FetchTimelineResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchTimelineResponseProcessor

@synthesize username, updateId, page, count, delegate, context;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                               page:aPage
                                              count:aCount
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                   username:(NSString *)aUsername
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                           username:aUsername
                                               page:aPage
                                              count:aCount
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
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    return [self initWithUpdateId:anUpdateId
                         username:nil
                             page:aPage
                            count:aCount
                          context:aContext
                         delegate:aDelegate];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
              username:(NSString *)aUsername
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.updateId = anUpdateId;
        self.page = aPage;
        self.count = aCount;
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
        NSString * userId = [[userData objectForKey:@"id"] description];
        User * tweetAuthor = [User userWithId:userId context:context];

        if (!tweetAuthor)
            tweetAuthor = [User createInstance:context];

        // only set user data the first time we see it, so we are saving
        // the freshest data
        if (![uniqueUsers containsObject:userId]) {
            [self populateUser:tweetAuthor fromData:userData];
            [uniqueUsers addObject:userId];
        }

        NSDictionary * tweetData = status;

        NSString * tweetId = [[tweetData objectForKey:@"id"] description];
        Tweet * tweet = [Tweet tweetWithId:tweetId context:context];

        // everything but the favorited count for tweets doesn't change
        if (!tweet) {
            tweet = [Tweet createInstance:context];

            tweet.identifier = tweetId;
            tweet.text = [tweetData objectForKey:@"text"];
            tweet.source = [tweetData objectForKey:@"source"];

            // already an NSDate instance
            tweet.timestamp = [tweetData objectForKey:@"created_at"];

            [tweet setValue:[tweetData objectForKey:@"truncated"]
                     forKey:@"truncated"];
            tweet.user = tweetAuthor;
        }

        // favorited count can change for a given tweet
        [tweet setValue:[tweetData objectForKey:@"favorited"]
                 forKey:@"favoritedCount"];

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
