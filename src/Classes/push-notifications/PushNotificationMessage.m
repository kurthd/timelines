//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "PushNotificationMessage.h"

@implementation PushNotificationMessage

@synthesize messageType, messageId, accountUsername;

- (void)dealloc
{
    [messageId release];
    [accountUsername release];
    [super dealloc];
}

- (id)initWithMessageType:(NSInteger)mt messageId:(NSNumber *)mid
    accountUsername:(NSString *)au
{
    if (self = [super init]) {
        messageType = mt;
        messageId = [mid copy];
        accountUsername = [au copy];
    }

    return self;
}

+ (id)parseFromString:(NSString *)notification
{
    //
    // Since this message comes from the server and could potentially
    // change in the future, be excessively defensive
    //

    PushNotificationMessage * message = nil;

    NSArray * comps = [notification componentsSeparatedByString:@"|"];
    if ([comps count] == 3) {
        NSString * account = [comps objectAtIndex:0];
        NSString * type = [comps objectAtIndex:1];
        NSString * objectIdAsString = [comps objectAtIndex:2];

        if (account && type && objectIdAsString) {
            NSNumber * objectId =
                [NSNumber numberWithLongLong:[objectIdAsString longLongValue]];
            if ([type isEqualToString:@"m"] || [type isEqualToString:@"d"]) {
                NSInteger messageType =
                    [type isEqualToString:@"m"] ?
                    kPushNotificationMessageTypeMention :
                    kPushNotificationMessageTypeDM;
                message =
                    [[[PushNotificationMessage alloc]
                    initWithMessageType:messageType messageId:objectId
                    accountUsername:account] autorelease];
            }
        }
    }

    return message;
}

+ (id)parseFromDictionary:(NSDictionary *)notification
{
    PushNotificationMessage * message = nil;
    NSString * messageString =
        [[notification objectForKey:@"version1"] objectForKey:@"message"];
    if (messageString)
        message = [PushNotificationMessage parseFromString:messageString];

    return message;
}

@end
