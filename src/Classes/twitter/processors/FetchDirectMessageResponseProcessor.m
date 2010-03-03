//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchDirectMessageResponseProcessor.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "DirectMessage.h"
#import "DirectMessage+CoreDataAdditions.h"
#import "TwitbitShared.h"

@interface FetchDirectMessageResponseProcessor ()

- (User *)userFromData:(NSDictionary *)data;

@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchDirectMessageResponseProcessor

@synthesize updateId, credentials, delegate, context;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                credentials:(TwitterCredentials *)someCredentials
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                        credentials:someCredentials
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.updateId = nil;
    self.credentials = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
           credentials:(TwitterCredentials *)someCredentials
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.updateId = anUpdateId;
        self.credentials = someCredentials;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)data
{
    if (!data)
        return NO;

    NSMutableArray * dms = [NSMutableArray arrayWithCapacity:data.count];
    for (NSDictionary * datum in data) {
        NSDictionary * senderData = [datum objectForKey:@"sender"];
        NSDictionary * recipientData = [datum objectForKey:@"recipient"];

        // If the user has an empty timeline, there will be one element and none
        // of the required data will be available.
        if (!senderData || !recipientData)
            continue;

        User * sender = [self userFromData:senderData];
        User * recipient = [self userFromData:recipientData];

        NSDictionary * dmData = datum;

        NSNumber * dmId = [[dmData objectForKey:@"id"] twitterIdentifierValue];

        NSPredicate * predicate =
            [NSPredicate predicateWithFormat:
             @"credentials.username == %@ and identifier == %@",
             self.credentials.username, dmId];
        DirectMessage * dm = [DirectMessage findFirst:predicate
                                              context:context];

        if (!dm) {
            dm = [DirectMessage createInstance:context];

            [self populateDirectMessage:dm fromData:dmData];

            dm.recipient = recipient;
            dm.sender = sender;
            dm.credentials = self.credentials;

            if ([credentials.username isEqualToString:sender.username])
                credentials.user = sender;
            else if ([credentials.username isEqualToString:recipient.username])
                credentials.user = recipient;
        }

        [dms addObject:dm];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save direct messages and users: '%@'", error);

    SEL sel = @selector(fetchedDirectMessage:withUpdateId:);
    if ([delegate respondsToSelector:sel])
        [delegate fetchedDirectMessage:[dms objectAtIndex:0]
                          withUpdateId:updateId];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchDirectMessageWithUpdateId:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchDirectMessageWithUpdateId:updateId
                                                   error:error];

    return YES;
}

#pragma mark Helper methods

- (User *)userFromData:(NSDictionary *)data
{
    NSNumber * userId = [[data objectForKey:@"id"] twitterIdentifierValue];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:data context:context];

    return user;
}

@end
