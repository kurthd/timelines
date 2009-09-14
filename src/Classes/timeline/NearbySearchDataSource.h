//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"
#import "TwitterServiceDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@interface NearbySearchDataSource :
    NSObject <TimelineDataSource, TwitterServiceDelegate>
{
    NSObject<TimelineDataSourceDelegate> * delegate;
    TwitterService * service;
    NSNumber * latitude;
    NSNumber * longitude;
    NSNumber * radiusInKm;
}

@property (nonatomic, assign) NSObject<TimelineDataSourceDelegate> * delegate;
@property (nonatomic, copy) NSNumber * latitude;
@property (nonatomic, copy) NSNumber * longitude;
@property (nonatomic, copy) NSNumber * radiusInKm;

- (id)initWithTwitterService:(TwitterService *)service
    latitude:(NSNumber *)latitude longitude:(NSNumber *)longitude
    radiusInKm:(NSNumber *)radiusInKem;

@end
