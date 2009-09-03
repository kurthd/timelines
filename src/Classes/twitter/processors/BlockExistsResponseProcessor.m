//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "BlockExistsResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface BlockExistsResponseProcessor ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation BlockExistsResponseProcessor

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

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSDictionary * info = [statuses objectAtIndex:0];
    NSString * userId = [[info objectForKey:@"id"] description];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:info];

    SEL sel = @selector(userIsBlocked:);
    [self invokeSelector:sel withTarget:delegate args:username, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    if ([error.domain isEqual:@"HTTP"] && error.code == 404) {
        // Twitter sends a 404 when a block does not exist
        SEL sel = @selector(userIsNotBlocked:);
        [self invokeSelector:sel withTarget:delegate args:username, nil];
    } else {
        // an actual error occurred
        SEL sel = @selector(failedToCheckIfUserIsBlocked:error:);
        [self invokeSelector:sel withTarget:delegate args:username, error, nil];
    }

    return YES;
}

@end
