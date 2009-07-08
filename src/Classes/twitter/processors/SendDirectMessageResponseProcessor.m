//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SendDirectMessageResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "DirectMessage.h"
#import "DirectMessage+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface SendDirectMessageResponseProcessor ()

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

- (User *)userFromData:(NSDictionary *)data;

@end

@implementation SendDirectMessageResponseProcessor

@synthesize text, username, context, credentials, delegate;

+ (id)processorWithTweet:(NSString *)someText
                username:(NSString *)aUsername
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithTweet:someText
                                        username:aUsername
                                     credentials:someCredentials
                                         context:aContext
                                        delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.text = nil;
    self.username = nil;
    self.credentials = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTweet:(NSString *)someText
           username:(NSString *)aUsername
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.text = someText;
        self.username = aUsername;
        self.credentials = someCredentials;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSAssert1(statuses.count == 1, @"Expected 1 status in response; received "
        "%d.", statuses.count);

    NSDictionary * status = [statuses lastObject];

    NSDictionary * senderData = [status objectForKey:@"sender"];
    NSDictionary * recipientData = [status objectForKey:@"recipient"];

    User * sender = [self userFromData:senderData];
    User * recipient = [self userFromData:recipientData];

    NSString * dmId = [[status objectForKey:@"id"] description];
    DirectMessage * dm = [DirectMessage directMessageWithId:dmId
                                                    context:context];

    if (!dm) {
        dm = [DirectMessage createInstance:context];

        [self populateDirectMessage:dm fromData:status];

        dm.recipient = recipient;
        dm.sender = sender;
        dm.credentials = self.credentials;
    }

    SEL sel = @selector(directMessage:sentToUser:);
    [self invokeSelector:sel withTarget:delegate args:dm, username, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToSendDirectMessage:toUser:error:);
    [self invokeSelector:sel withTarget:delegate args:text, username, error,
        nil];

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
