//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchListStatusesResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "UserTweet.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface FetchListStatusesResponseProcessor ()

@property (nonatomic, copy) NSNumber * listId;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FetchListStatusesResponseProcessor

@synthesize listId, username, updateId, page, count, delegate, context;

+ (id)processorWithListId:(NSNumber *)aListId
              ownedByUser:(NSString *)aUsername
            sinceUpdateId:(NSNumber *)anUpdateId
                     page:(NSNumber *)aPage
                    count:(NSNumber *)aCount
                  context:(NSManagedObjectContext *)aContext
                 delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id processor = [[[self class] alloc] initWithListId:aListId
                                            ownedByUser:aUsername
                                          sinceUpdateId:anUpdateId
                                                   page:aPage
                                                  count:aCount
                                                context:aContext
                                               delegate:aDelegate];
    return [processor autorelease];
}


- (void)dealloc
{
    self.listId = nil;
    self.username = nil;
    self.updateId = nil;
    self.page = nil;
    self.count = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithListId:(NSNumber *)aListId
         ownedByUser:(NSString *)aUsername
       sinceUpdateId:(NSNumber *)anUpdateId
                page:(NSNumber *)aPage
               count:(NSNumber *)aCount
             context:(NSManagedObjectContext *)aContext
            delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.listId = aListId;
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
    for (NSDictionary * status in statuses) {
        Tweet * tweet = [self createTweetFromStatus:status
                                        isUserTweet:NO
                                     isSearchResult:NO
                                        credentials:nil
                                            context:self.context];
        if (tweet)
            [tweets addObject:tweet];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    SEL sel =
        @selector(statuses:fetchedForListId:ownedByUser:sinceUpdateId:page:\
        count:);
    if ([delegate respondsToSelector:sel])
        [delegate statuses:tweets fetchedForListId:listId ownedByUser:username
            sinceUpdateId:updateId page:page count:count];


    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchStatusesForListId:ownedByUser:\
        sinceUpdateId:page:count:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchStatusesForListId:listId
                                     ownedByUser:username
                                   sinceUpdateId:updateId
                                            page:page
                                           count:count
                                           error:error];

    return YES;
}

@end
