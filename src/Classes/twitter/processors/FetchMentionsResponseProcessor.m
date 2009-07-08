//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchMentionsResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Mention.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface FetchMentionsResponseProcessor ()

@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchMentionsResponseProcessor

@synthesize updateId, page, count, credentials, delegate, context;

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

- (void)dealloc
{
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
    if (self = [super init]) {
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
        User * user = [User userWithId:userId context:context];

        if (!user)
            user = [User createInstance:context];

        // only set user data the first time we see it, so we are saving
        // the freshest data
        if (![uniqueUsers containsObject:userId]) {
            [self populateUser:user fromData:userData];
            [uniqueUsers addObject:userId];
        }

        NSDictionary * tweetData = status;

        NSString * tweetId = [[tweetData objectForKey:@"id"] description];
        Mention * tweet = [Mention tweetWithId:tweetId context:context];
        if (!tweet)
            tweet = [Mention createInstance:context];

        [self populateTweet:tweet fromData:tweetData];
        tweet.user = user;
        tweet.credentials = self.credentials;

        [tweets addObject:tweet];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save mentions and users: '%@'", error);

    SEL sel = @selector(mentions:fetchedSinceUpdateId:page:count:);
    [self invokeSelector:sel withTarget:delegate args:tweets, updateId, page,
        count, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchMentionsSinceUpdateId:page:count:error:);
    [self invokeSelector:sel withTarget:delegate args:updateId, page, count,
        error, nil];

    return YES;
}

@end
