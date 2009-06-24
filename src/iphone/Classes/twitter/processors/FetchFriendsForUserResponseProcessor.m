//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchFriendsForUserResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface FetchFriendsForUserResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchFriendsForUserResponseProcessor

@synthesize username, page, context, delegate;

+ (id)processorWithUsername:(NSString *)aUsername
                       page:(NSNumber *)aPage
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
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
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.page = aPage;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)infos
{
    if (!infos)
        return NO;

    NSMutableArray * users = [NSMutableArray arrayWithCapacity:infos.count];
    for (NSDictionary * info in infos) {
        NSString * userId = [[info objectForKey:@"id"] description];
        User * user = [User userWithId:userId context:context];

        if (!user)
            user = [User createInstance:context];

        [self populateUser:user fromData:info];
        [users addObject:user];
    }

    SEL sel = @selector(friends:fetchedForUsername:page:);
    [self invokeSelector:sel withTarget:delegate args:users, username, page,
        nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchFriendsForUsername:page:error:);
    [self invokeSelector:sel withTarget:delegate args:username, page, error,
        nil];

    return YES;
}

@end
