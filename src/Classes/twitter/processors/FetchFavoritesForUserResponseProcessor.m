//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchFavoritesForUserResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface FetchFavoritesForUserResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FetchFavoritesForUserResponseProcessor

@synthesize username, page, delegate, context;

+ (id)processorWithUsername:(NSString *)aUsername
                       page:(NSNumber *)aPage
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
                                               page:aPage
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.username = nil;
    self.page = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername
                  page:(NSNumber *)aPage
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.page = aPage;
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

        NSNumber * userId =
            [[userData objectForKey:@"id"] twitterIdentifierValue];
        User * tweetAuthor = [User findOrCreateWithId:userId context:context];

        // only set user data the first time we see it, so we are saving
        // the freshest data
        if (![uniqueUsers containsObject:userId]) {
            [self populateUser:tweetAuthor fromData:userData];
            [uniqueUsers addObject:userId];
        }

        NSDictionary * tweetData = status;

        NSNumber * tweetId =
            [[tweetData objectForKey:@"id"] twitterIdentifierValue];
        Tweet * tweet = [Tweet tweetWithId:tweetId context:context];

        if (!tweet)
            tweet = [Tweet createInstance:context];

        [self populateTweet:tweet fromData:tweetData
            isSearchResult:NO context:context];
        tweet.user = tweetAuthor;

        [tweets addObject:tweet];
    }

    SEL sel = @selector(favorites:fetchedForUser:page:);
    if ([delegate respondsToSelector:sel])
        [delegate favorites:tweets fetchedForUser:username page:page];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchFavoritesForUser:page:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchFavoritesForUser:username page:page error:error];

    return YES;
}

@end
