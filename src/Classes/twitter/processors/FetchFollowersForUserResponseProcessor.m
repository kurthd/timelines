//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchFollowersForUserResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "TwitbitShared.h"

@interface FetchFollowersForUserResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * cursor;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FetchFollowersForUserResponseProcessor

@synthesize username, cursor, context, delegate;

+ (id)processorWithUsername:(NSString *)aUsername
                     cursor:(NSString *)aCursor
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
                                             cursor:aCursor
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.username = nil;
    self.cursor = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername
                cursor:(NSString *)aCursor
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.cursor = aCursor;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)rawResponse
{
    if (!rawResponse)
        return NO;

    NSDictionary * response = [rawResponse objectAtIndex:0];
    NSString * nextCursor =
        [[response objectForKey:@"next_cursor"] description];
    NSArray * infos = [response objectForKey:@"users"];

    NSMutableArray * users = [NSMutableArray arrayWithCapacity:infos.count];
    for (NSDictionary * info in infos) {
        NSNumber * userId =
            [[info objectForKey:@"id"] twitterIdentifierValue];
        if (!userId)
            // asking for more when there are none gives us an element in the
            // dictionary with one element named 'friends'
            continue;

        User * user = [User findOrCreateWithId:userId context:context];
        [self populateUser:user fromData:info];
        [users addObject:user];
    }

    SEL sel = @selector(followers:fetchedForUsername:cursor:nextCursor:);
    if ([delegate respondsToSelector:sel])
        [delegate followers:users fetchedForUsername:username
                  cursor:cursor nextCursor:nextCursor];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchFollowersForUsername:cursor:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchFollowersForUsername:username
                                             cursor:cursor
                                              error:error];

    return YES;
}

@end
