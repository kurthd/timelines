//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DeviceRegistrarDelegate

- (void)registeredDeviceWithToken:(NSData *)token;
- (void)failedToRegisterDeviceWithToken:(NSData *)token error:(NSError *)error;

@end
