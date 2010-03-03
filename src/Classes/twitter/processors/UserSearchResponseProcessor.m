//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UserSearchResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "TwitbitShared.h"

@interface UserSearchResponseProcessor ()

@property (nonatomic, copy) NSString * query;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation UserSearchResponseProcessor

@synthesize query, count, page, context, delegate;

+ (id)processorWithQuery:(NSString *)aQuery
                   count:(NSNumber *)aCount
                    page:(NSNumber *)aPage
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithQuery:aQuery
                                           count:aCount
                                            page:aPage
                                         context:aContext
                                        delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.query = nil;
    self.count = nil;
    self.page = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithQuery:(NSString *)aQuery
              count:(NSNumber *)aCount
               page:(NSNumber *)aPage
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.query = aQuery;
        self.count = aCount;
        self.page = aPage;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)response
{
    if (!response)
        return NO;

    NSMutableArray * users = [NSMutableArray arrayWithCapacity:response.count];
    for (NSDictionary * userData in response) {
        NSNumber * userId =
            [[userData objectForKey:@"id"] twitterIdentifierValue];
        User * user = [User findOrCreateWithId:userId context:context];
        [self populateUser:user fromData:userData context:context];
        [users addObject:user];
    }

    SEL sel = @selector(userSearchResultsReceived:forQuery:count:page:);
    if ([delegate respondsToSelector:sel])
        [delegate userSearchResultsReceived:users
                                   forQuery:query
                                      count:count
                                       page:page];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToSearchUsersForQuery:count:page:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToSearchUsersForQuery:query
                                        count:count
                                         page:page
                                        error:error];

    return YES;
}

@end
