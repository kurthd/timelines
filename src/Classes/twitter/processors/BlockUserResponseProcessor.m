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
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation BlockUserResponseProcessor

@synthesize username, blocking, context, delegate;

+ (id)processorWithUsername:(NSString *)aUsername
                   blocking:(BOOL)isBlocking
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
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
              delegate:(id<TwitterServiceDelegate>)aDelegate
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
    NSNumber * userId = [info objectForKey:@"id"];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:info];

    if (blocking) {
        SEL sel = @selector(blockedUser:withUsername:);
        if ([delegate respondsToSelector:sel])
            [delegate blockedUser:user withUsername:username];
    } else {
        SEL sel = @selector(unblockedUser:withUsername:);
        if ([delegate respondsToSelector:sel])
            [delegate unblockedUser:user withUsername:username];
    }

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSLog(@"Failed to block user '%@': %@.", username, error);

    if (blocking) {
        SEL sel = @selector(failedToBlockUserWithUsername:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToBlockUserWithUsername:username error:error];
    } else {
        SEL sel = @selector(failedToUnblockUserWithUsername:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToUnblockUserWithUsername:username error:error];
    }

    return YES;
}

@end
