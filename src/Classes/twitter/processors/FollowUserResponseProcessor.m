//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FollowUserResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface FollowUserResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, assign) BOOL following;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FollowUserResponseProcessor

@synthesize username, following, context, delegate;
 
+ (id)processorWithUsername:(NSString *)aUsername
                  following:(BOOL)isFollowing
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
                                          following:isFollowing
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
             following:(BOOL)isFollowing
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.username = aUsername;
        self.following = isFollowing;
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

    NSNumber * userId = [info objectForKey:@"id"];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:info];

    SEL sel;
    if (following)
        sel = @selector(startedFollowingUsername:);
    else
        sel = @selector(stoppedFollowingUsername:);

    [delegate performSelector:sel withObject:username];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel;
    if (following)
        sel = @selector(failedToStartFollowingUsername:error:);
    else
        sel = @selector(failedToStopFollowingUsername:error:);

    [delegate performSelector:sel withObject:username withObject:error];

    return YES;
}

@end
