//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeleteDirectMessageResponseProcessor.h"
#import "DirectMessage.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface DeleteDirectMessageResponseProcessor ()

@property (nonatomic, copy) NSString * directMessageId;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation DeleteDirectMessageResponseProcessor

@synthesize directMessageId, context, delegate;

+ (id)processorWithDirectMessageId:(NSString *)aDirectMessageId
                           context:(NSManagedObjectContext *)aContext
                          delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithDirectMessageId:aDirectMessageId
                                                   context:aContext
                                                  delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.directMessageId = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithDirectMessageId:(NSString *)aDirectMessageId
                      context:(NSManagedObjectContext *)aContext
                     delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.directMessageId = aDirectMessageId;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSLog(@"Deleted direct message %@: %@.", directMessageId, statuses);

    // Notify the delegate first so it can do whatever it needs to do with the
    // Direct Message object.
    SEL sel = @selector(deletedDirectMessageWithId:);
    [self invokeSelector:sel withTarget:delegate args:directMessageId, nil];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"identifier == %@", directMessageId];
    DirectMessage * dm = [DirectMessage findFirst:predicate context:context];
    NSAssert1(dm, @"Failed to find expected direct message with ID so it can "
        "be deleted: '%@'.", directMessageId);
    [context deleteObject:dm];
    [context save:NULL];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSLog(@"Failed to delete direct message: %@.", error);

    SEL sel = @selector(failedToDeleteDirectMessageWithId:error:);
    [self invokeSelector:sel withTarget:delegate args:directMessageId, error,
        nil];

    return YES;
}

@end
