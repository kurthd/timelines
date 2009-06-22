//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchDirectMessagesResponseProcessor.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "DirectMessage.h"
#import "DirectMessage+CoreDataAdditions.h"

@interface FetchDirectMessagesResponseProcessor ()

- (User *)userFromData:(NSDictionary *)data;

@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchDirectMessagesResponseProcessor

@synthesize updateId, page, delegate, context;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                               page:aPage
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.updateId = nil;
    self.page = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.updateId = anUpdateId;
        self.page = aPage;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (void)processResponse:(NSArray *)data
{
    if (!data)
        return;

    NSLog(@"Received direct messages: %@", data);

    NSMutableArray * dms = [NSMutableArray arrayWithCapacity:data.count];
    for (NSDictionary * datum in data) {
        NSDictionary * senderData = [datum objectForKey:@"sender"];
        NSDictionary * recipientData = [datum objectForKey:@"recipient"];

        User * sender = [self userFromData:senderData];
        User * recipient = [self userFromData:recipientData];

        NSLog(@"Have sender: '%@'.", sender);
        NSLog(@"Have recipient: '%@'.", recipient);

        NSDictionary * dmData = datum;

        NSString * dmId = [[dmData objectForKey:@"id"] description];
        DirectMessage * dm = [DirectMessage directMessageWithId:dmId
                                                        context:context];

        if (!dm) {
            dm = [DirectMessage createInstance:context];

            dm.identifier = dmId;
            dm.text = [dmData objectForKey:@"text"];
            dm.sourceApiRequestType =
                [[dmData objectForKey:@"source_api_request_type"] description];

            // already an NSData instance
            dm.created = [dmData objectForKey:@"created_at"];

            dm.recipient = recipient;
            dm.sender = sender;
        }

        [dms addObject:dm];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    SEL sel = @selector(directMessages:fetchedSinceUpdateId:page:);
    [self invokeSelector:sel withTarget:delegate args:dms, updateId, page,
        nil];
}

- (void)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchDirectMessagesSinceUpdateId:page:error:);
    [self invokeSelector:sel withTarget:delegate args:updateId, page, error,
        nil];
}

#pragma mark Helper methods

- (User *)userFromData:(NSDictionary *)data
{
    NSString * userId = [[data objectForKey:@"id"] description];
    User * user = [User userWithId:userId context:context];

    if (!user)
        user = [User createInstance:context];

    [self populateUser:user fromData:data];

    return user;
}

@end
