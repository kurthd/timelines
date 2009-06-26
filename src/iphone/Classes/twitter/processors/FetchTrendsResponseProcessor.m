//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTrendsResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface FetchTrendsResponseProcessor ()

@property (nonatomic, assign) TrendFetchType trendType;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchTrendsResponseProcessor

@synthesize trendType, context, delegate;

+ (id)processorWithTrendFetchType:(TrendFetchType)aTrendFetchType
                          context:(NSManagedObjectContext *)aContext
                         delegate:(id)aDelegate
{
    return [[[[self class] alloc] initWithTrendFetchType:aTrendFetchType
                                            context:aContext
                                           delegate:aDelegate] autorelease];
}

- (void)dealloc
{
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTrendFetchType:(TrendFetchType)aTrendFetchType
                     context:(NSManagedObjectContext *)aContext
                    delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.trendType = aTrendFetchType;
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
        if (!tweet)
            tweet = [Tweet createInstance:context];

        [self populateTweet:tweet fromData:tweetData];
        tweet.user = tweetAuthor;

        [tweets addObject:tweet];
    }

    SEL sel;
    switch (trendType) {
        case kFetchCurrentTrends:
            sel = @selector(fetchedCurrentTrends:);
            break;
        case kFetchDailyTrends:
            sel = @selector(fetchedDailyTrends:);
            break;
        case kFetchWeeklyTrends:
            sel = @selector(fetchedWeeklyTrends:);
            break;
    }
    [self invokeSelector:sel withTarget:delegate args:tweets, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel;
    switch (trendType) {
        case kFetchCurrentTrends:
            sel = @selector(failedToFetchCurrentTrends:);
            break;
        case kFetchDailyTrends:
            sel = @selector(failedToFetchDailyTrends:);
            break;
        case kFetchWeeklyTrends:
            sel = @selector(failedToFetchWeeklyTrends:);
            break;
    }
    [self invokeSelector:sel withTarget:delegate args:error, nil];

    return YES;
}


@end
