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
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, assign) BOOL sent;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchDirectMessagesResponseProcessor

@synthesize updateId, page, count, sent, credentials, delegate, context;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                       sent:(BOOL)isSent
                credentials:(TwitterCredentials *)someCredentials
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                               page:aPage
                                              count:aCount
                                               sent:isSent
                                        credentials:someCredentials
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.updateId = nil;
    self.page = nil;
    self.count = nil;
    self.credentials = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
                  sent:(BOOL)isSent
           credentials:(TwitterCredentials *)someCredentials
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.updateId = anUpdateId;
        self.page = aPage;
        self.count = aCount;
        self.sent = isSent;
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

        NSString * dmId = [[dmData objectForKey:@"id"] description];
        DirectMessage * dm = [DirectMessage directMessageWithId:dmId
                                                        context:context];

        if (!dm) {
            dm = [DirectMessage createInstance:context];

            [self populateDirectMessage:dm fromData:dmData];

            dm.recipient = recipient;
            dm.sender = sender;
            dm.credentials = self.credentials;
        }

        [dms addObject:dm];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    SEL sel;
    if (sent)
        sel = @selector(sentDirectMessages:fetchedSinceUpdateId:page:count:);
    else
        sel = @selector(directMessages:fetchedSinceUpdateId:page:count:);

    [self invokeSelector:sel withTarget:delegate args:dms, updateId, page,
        count, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel;
    if (sent)
        sel = @selector(failedToFetchSentDirectMessagesSinceUpdateId:page:\
            count:error:);
    else
        sel = @selector(failedToFetchDirectMessagesSinceUpdateId:page:count:\
            error:);
        
    [self invokeSelector:sel withTarget:delegate args:updateId, page, count,
        error, nil];

    return YES;
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
