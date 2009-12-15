//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    kPushNotificationMessageTypeMention,
    kPushNotificationMessageTypeDM
} PushNotificationMessageType;

@interface PushNotificationMessage : NSObject
{
    NSInteger messageType;
    NSNumber * messageId;
    NSString * accountUsername;
}

- (id)initWithMessageType:(NSInteger)messageType messageId:(NSNumber *)messageId
    accountUsername:(NSString *)accountUsername;

+ (id)parseFromString:(NSString *)notification;
+ (id)parseFromDictionary:(NSDictionary *)notification;
    
@property (nonatomic, readonly) NSInteger messageType;
@property (nonatomic, readonly) NSNumber * messageId;
@property (nonatomic, readonly) NSString * accountUsername;

@end
