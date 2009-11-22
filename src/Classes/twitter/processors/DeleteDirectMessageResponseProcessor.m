//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeleteDirectMessageResponseProcessor.h"
#import "DirectMessage.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "MGTwitterEngine.h"  // for [NSError twitterApiErrorDomain]

@interface DeleteDirectMessageResponseProcessor ()

@property (nonatomic, copy) NSNumber * directMessageId;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

- (BOOL)physicallyDeleteDirectMessageWithId:(NSNumber *)dmId;

@end

@implementation DeleteDirectMessageResponseProcessor

@synthesize directMessageId, context, delegate;

+ (id)processorWithDirectMessageId:(NSNumber *)aDirectMessageId
                           context:(NSManagedObjectContext *)aContext
                          delegate:(id<TwitterServiceDelegate>)aDelegate
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

- (id)initWithDirectMessageId:(NSNumber *)aDirectMessageId
                      context:(NSManagedObjectContext *)aContext
                     delegate:(id<TwitterServiceDelegate>)aDelegate
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
    if ([delegate respondsToSelector:sel])
        [delegate deletedDirectMessageWithId:directMessageId];

    [self physicallyDeleteDirectMessageWithId:directMessageId];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSLog(@"Failed to delete direct message: %@.", error);

    SEL sel = @selector(failedToDeleteDirectMessageWithId:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToDeleteDirectMessageWithId:directMessageId
                                              error:error];

    // if the message has already been deleted on the server, delete our local
    // copy
    BOOL alreadyDeletedOnServer =
        [[error domain] isEqualToString:[NSError twitterApiErrorDomain]] &&
        [error code] == 404;
    if (alreadyDeletedOnServer)
        [self physicallyDeleteDirectMessageWithId:directMessageId];

    return YES;
}

#pragma mark Private implementation

- (BOOL)physicallyDeleteDirectMessageWithId:(NSNumber *)dmId
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"identifier == %@", directMessageId];
    DirectMessage * dm = [DirectMessage findFirst:predicate context:context];

    if (dm) {
        [context deleteObject:dm];
        return [context save:NULL];
    }

    return NO;
}

@end
