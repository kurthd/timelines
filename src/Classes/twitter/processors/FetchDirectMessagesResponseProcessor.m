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
                   delegate:(id<TwitterServiceDelegate>)aDelegate
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
              delegate:(id<TwitterServiceDelegate>)aDelegate
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

    id<JsonObjectFilter> filter =
        [[UserEntityJsonObjectFilter alloc]
        initWithManagedObjectContext:context
                         credentials:credentials
                          entityName:@"DirectMessage"];

    id<JsonObjectTransformer> transformer =
        [DirectMessageJsonObjectTransformer instance];

    id<TwitbitObjectCreator> userCreator =
        [[UserTwitbitObjectCreator alloc] initWithManagedObjectContext:context];
    id<TwitbitObjectCreator> creator =
        [[DirectMessageTwitbitObjectCreator alloc]
        initWithManagedObjectContext:context
                         userCreator:userCreator
                         credentials:credentials];
    [userCreator release];

    TwitbitObjectBuilder * builder =
        [[TwitbitObjectBuilder alloc] initWithFilter:filter
                                         transformer:transformer
                                             creator:creator];
    builder.delegate = self;

    [filter release];
    [creator release];

    [builder buildObjectsFromJsonObjects:data];

    [self retain];

    return YES;
}

- (void)objectBuilder:(TwitbitObjectBuilder *)builder
      didBuildObjects:(NSArray *)objects
{
    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save direct messages and users: '%@'",
            [error detailedDescription]);

    if (sent) {
        SEL sel =
            @selector(sentDirectMessages:fetchedSinceUpdateId:page:count:);
        if ([delegate respondsToSelector:sel])
            [delegate sentDirectMessages:objects
                    fetchedSinceUpdateId:self.updateId
                                    page:self.page
                                   count:self.count];
    } else {
        SEL sel = @selector(directMessages:fetchedSinceUpdateId:page:count:);
        if ([delegate respondsToSelector:sel])
            [delegate directMessages:objects
                fetchedSinceUpdateId:self.updateId
                                page:self.page
                               count:self.count];
    }
}

- (BOOL)processResponseSynchronous:(NSArray *)data
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

    if (sent) {
        SEL sel =
            @selector(sentDirectMessages:fetchedSinceUpdateId:page:count:);
        if ([delegate respondsToSelector:sel])
            [delegate sentDirectMessages:dms
                    fetchedSinceUpdateId:self.updateId
                                    page:self.page
                                   count:self.count];
    } else {
        SEL sel = @selector(directMessages:fetchedSinceUpdateId:page:count:);
        if ([delegate respondsToSelector:sel])
            [delegate directMessages:dms
                fetchedSinceUpdateId:self.updateId
                                page:self.page
                               count:self.count];
    }

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel;
    if (sent) {
        sel = @selector(failedToFetchSentDirectMessagesSinceUpdateId:page:\
            count:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToFetchSentDirectMessagesSinceUpdateId:updateId
                                                              page:page
                                                             count:count
                                                             error:error];
    } else {
        sel = @selector(failedToFetchDirectMessagesSinceUpdateId:page:count:\
            error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToFetchDirectMessagesSinceUpdateId:updateId
                                                          page:page
                                                         count:count
                                                         error:error];
    }

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
