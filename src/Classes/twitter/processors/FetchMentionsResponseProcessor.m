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

#import "JsonObjectFilter.h"
#import "TwitbitObjectBuilder.h"

@interface FetchMentionsResponseProcessor ()

@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FetchMentionsResponseProcessor

@synthesize updateId, page, count, credentials, delegate, context;

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
              delegate:(id<TwitterServiceDelegate>)aDelegate
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

    id<JsonObjectFilter> filter =
        [[UserEntityJsonObjectFilter alloc]
        initWithManagedObjectContext:context
                         credentials:credentials
                          entityName:@"Mention"];
    id<JsonObjectTransformer> transformer =
        [SimpleJsonObjectTransformer instance];

    id<TwitbitObjectCreator> userCreator =
        [[UserTwitbitObjectCreator alloc] initWithManagedObjectContext:context];
    id<TwitbitObjectCreator> retweetCreator =
        [[TweetTwitbitObjectCreator alloc]
        initWithManagedObjectContext:context
                         userCreator:userCreator
                      retweetCreator:nil];
    id<TwitbitObjectCreator> creator =
        [[UserEntityTwitbitObjectCreator alloc]
        initWithManagedObjectContext:context
                         userCreator:userCreator
                      retweetCreator:retweetCreator
                         credentials:credentials
                          entityName:@"Mention"];
    [userCreator release];
    [retweetCreator release];

    TwitbitObjectBuilder * builder =
        [[TwitbitObjectBuilder alloc] initWithFilter:filter
                                         transformer:transformer
                                             creator:creator];
    builder.delegate = self;

    [filter release];
    [creator release];

    [builder buildObjectsFromJsonObjects:statuses];

    [self retain];

    return YES;
}

- (void)objectBuilder:(TwitbitObjectBuilder *)builder
      didBuildObjects:(NSArray *)objects
{
    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save mentions and users: '%@'", error);


    SEL sel = @selector(mentions:fetchedSinceUpdateId:page:count:);
    if ([delegate respondsToSelector:sel])
        [delegate mentions:objects fetchedSinceUpdateId:updateId page:page
            count:count];

    [builder autorelease];
    [self autorelease];
}

- (BOOL)processResponseSynchronous:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSMutableArray * tweets = [NSMutableArray arrayWithCapacity:statuses.count];
    for (id status in statuses) {
        Mention * tweet = [self createMentionFromStatus:status
                                            credentials:self.credentials
                                                context:self.context];
        if (tweet)
            [tweets addObject:tweet];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save mentions and users: '%@'", error);


    SEL sel = @selector(mentions:fetchedSinceUpdateId:page:count:);
    if ([delegate respondsToSelector:sel])
        [delegate mentions:tweets fetchedSinceUpdateId:updateId page:page
            count:count];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchMentionsSinceUpdateId:page:count:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchMentionsSinceUpdateId:updateId page:page
            count:count error:error];

    return YES;
}

@end
