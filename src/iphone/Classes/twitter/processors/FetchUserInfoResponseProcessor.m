//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchUserInfoResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface FetchUserInfoResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchUserInfoResponseProcessor

@synthesize username, context, delegate;
 
+ (id)processorWithUsername:(NSString *)aUsername
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
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
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)infos
{
    if (!infos)
        return NO;

    NSAssert1(infos.count == 1, @"Expected 1 user info but received: %d.",
        infos.count);
    NSDictionary * info = [infos objectAtIndex:0];

    NSString * userId = [[info objectForKey:@"id"] description];
    User * user = [User userWithId:userId context:context];

    if (!user)
        user = [User createInstance:context];

    [self populateUser:user fromData:info];

    SEL sel = @selector(userInfo:fetchedForUsername:);
    [self invokeSelector:sel withTarget:delegate args:user, username, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchUserInfoForUsername:error:);
    [self invokeSelector:sel withTarget:delegate args:username, error, nil];

    return YES;
}

@end
