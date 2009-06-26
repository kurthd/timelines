//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface NSDictionary (CopyAndPastedParsingHelpers)
- (id)safeObjectForKey:(id)key;
@end

@implementation NSDictionary (CopyAndPastedParsingHelpers)
- (id)safeObjectForKey:(id)key
{
    id obj = [self objectForKey:key];
    return [obj isEqual:[NSNull null]] ? nil : obj;
}
@end

@interface SearchResponseProcessor ()

@property (nonatomic, copy) NSString * query;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation SearchResponseProcessor

@synthesize query, page, delegate, context;

+ (id)processorWithQuery:(NSString *)aQuery
                    page:(NSNumber *)aPage
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithQuery:aQuery
                                            page:aPage
                                         context:aContext
                                        delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.query = nil;
    self.page = nil;
    self.delegate = nil;
    self.context = nil;
    [super dealloc];
}

- (id)initWithQuery:(NSString *)aQuery
               page:(NSNumber *)aPage
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.query = aQuery;
        self.page = aPage;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

#pragma mark Processing responses

- (BOOL)processResponse:(NSArray *)results
{
    if (!results)
        return NO;

    NSMutableArray * tweets = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary * result in results) {
        if ([result objectForKey:@"refresh_url"])
            continue;  // metadata, not a search result
    
        NSDictionary * userData = result;

        // the user ids in the search result are wrong per twitter:
        //   http://code.google.com/p/twitter-api/issues/detail?id=214
        NSString * userId =
            [[userData objectForKey:@"from_user_id"] description];
        User * tweetAuthor = [User userWithId:userId context:context];

        if (!tweetAuthor)
            tweetAuthor = [User createInstance:context];

        tweetAuthor.created = [NSDate date];
        tweetAuthor.username = [userData objectForKey:@"from_user"];
        tweetAuthor.identifier = userId;
        tweetAuthor.profileImageUrl =
            [userData objectForKey:@"profile_image_url"];

        NSDictionary * tweetData = result;

        NSString * tweetId = [[tweetData objectForKey:@"id"] description];
        Tweet * tweet = [Tweet tweetWithId:tweetId context:context];
        if (!tweet)
            tweet = [Tweet createInstance:context];

        tweet.identifier = tweetId;
        tweet.text = [tweetData safeObjectForKey:@"text"];
        tweet.source = [tweetData safeObjectForKey:@"source"];
        
        // timestamp is in the 'created_at' field, but is always set to
        // 1969-12-31; fix once twitter results are fixed -- could be mg
        // twitter engine or twitter itself
        tweet.timestamp = nil;

        tweet.user = tweetAuthor;

        [tweets addObject:tweet];
    }

    SEL sel = @selector(searchResultsReceived:forQuery:page:);
    [self invokeSelector:sel withTarget:delegate args:tweets, query, page,
        nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchSearchResultsForQuery:page:error:);
    [self invokeSelector:sel withTarget:delegate args:query, page, error, nil];

    return YES;
}

@end
