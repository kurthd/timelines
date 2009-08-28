//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "BlockUserResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface BlockUserResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, assign) BOOL blocking;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation BlockUserResponseProcessor

@synthesize username, blocking, context, delegate;

+ (id)processorWithUsername:(NSString *)aUsername
                   blocking:(BOOL)isBlocking
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
                                           blocking:isBlocking
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.username = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername
              blocking:(BOOL)isBlocking
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.blocking = isBlocking;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSLog(@"Blocked user '%@': %@.", username, statuses);

    NSDictionary * info = [statuses objectAtIndex:0];
    NSString * userId = [[info objectForKey:@"id"] description];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:info];

    SEL sel =
        blocking ?
        @selector(blockedUser:withUsername:) :
        @selector(unblockedUser:withUsername:);

    [self invokeSelector:sel withTarget:delegate args:user, username, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSLog(@"Failed to block user '%@': %@.", username, error);

    SEL sel =
        blocking ?
        @selector(failedToBlockUserWithUsername:error:) :
        @selector(failedToUnblockUserWithUsername:error:);

    [self invokeSelector:sel withTarget:delegate args:username, error, nil];

    return YES;
}

@end
