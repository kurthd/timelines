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
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FetchTimelineResponseProcessor

@synthesize username, updateId, page, count, credentials, delegate, context;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                credentials:(TwitterCredentials *)someCredentials
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
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
                   delegate:(id<TwitterServiceDelegate>)aDelegate
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
              delegate:(id<TwitterServiceDelegate>)aDelegate
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
              delegate:(id<TwitterServiceDelegate>)aDelegate
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
    for (NSDictionary * status in statuses) {
        Tweet * tweet = [self createTweetFromStatus:status
                                        isUserTweet:!self.username
                                     isSearchResult:NO
                                        credentials:self.credentials
                                            context:self.context];

        NSDictionary * retweetData = [status objectForKey:@"retweeted_status"];
        if (retweetData) {
            Tweet * retweet = [self createTweetFromStatus:retweetData
                                              isUserTweet:!self.username
                                           isSearchResult:NO
                                              credentials:self.credentials
                                                  context:context];
            tweet.retweet = retweet;
        }

        if (tweet)
            [tweets addObject:tweet];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    if (self.username) {
        SEL sel = @selector(timeline:fetchedForUser:sinceUpdateId:page:count:);
        if ([delegate respondsToSelector:sel])
            [delegate timeline:tweets fetchedForUser:username
                sinceUpdateId:updateId page:page count:count];
    } else {
        SEL sel = @selector(timeline:fetchedSinceUpdateId:page:count:);
        if ([delegate respondsToSelector:sel])
            [delegate timeline:tweets fetchedSinceUpdateId:updateId page:page
                count:count];
    }

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    if (self.username) {
        SEL sel = @selector(failedToFetchTimelineForUser:sinceUpdateId:page:\
            count:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToFetchTimelineForUser:username
                                     sinceUpdateId:updateId
                                              page:page
                                             count:count
                                             error:error];
    } else {
        SEL sel =
            @selector(failedToFetchTimelineSinceUpdateId:page:count:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToFetchTimelineSinceUpdateId:updateId
                                                    page:page
                                                   count:count
                                                   error:error];
    }

    return YES;
}

@end
