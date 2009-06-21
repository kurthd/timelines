//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceRegistrar : NSObject
{
}

- (void)sendProviderDeviceToken:(NSData *)devToken args:(NSDictionary *)args;

@end
