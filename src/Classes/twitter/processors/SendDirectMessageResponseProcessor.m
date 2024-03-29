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
#import "TwitbitShared.h"

@interface SendDirectMessageResponseProcessor ()

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

- (User *)userFromData:(NSDictionary *)data;

@end

@implementation SendDirectMessageResponseProcessor

@synthesize text, username, context, credentials, delegate;

+ (id)processorWithTweet:(NSString *)someText
                username:(NSString *)aUsername
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate
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
           delegate:(id<TwitterServiceDelegate>)aDelegate
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

    NSNumber * dmId = [[status objectForKey:@"id"] twitterIdentifierValue];
    DirectMessage * dm =
        [DirectMessage directMessageWithId:dmId context:context];

    if (!dm) {
        dm = [DirectMessage createInstance:context];

        [self populateDirectMessage:dm fromData:status];

        dm.recipient = recipient;
        dm.sender = sender;
        dm.credentials = self.credentials;

        if ([credentials.username isEqualToString:sender.username])
            credentials.user = sender;
        else if ([credentials.username isEqualToString:recipient.username])
            credentials.user = recipient;
    }

    SEL sel = @selector(directMessage:sentToUser:);
    if ([delegate respondsToSelector:sel])
        [delegate directMessage:dm sentToUser:username];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToSendDirectMessage:toUser:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToSendDirectMessage:text toUser:username error:error];

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
