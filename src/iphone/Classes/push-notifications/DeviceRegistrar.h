//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceRegistrarDelegate.h"

@interface DeviceRegistrar : NSObject
{
    id<DeviceRegistrarDelegate> delegate;

    NSString * urlString;

    NSData * deviceToken;
}

@property (nonatomic, assign) id<DeviceRegistrarDelegate> delegate;
@property (nonatomic, copy, readonly) NSString * urlString;

- (id)initWithUrl:(NSString *)aUrl;

- (void)sendProviderDeviceToken:(NSData *)devToken args:(NSDictionary *)args;

@end
