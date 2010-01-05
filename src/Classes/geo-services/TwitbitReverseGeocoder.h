//
//  Copyright 2010 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitbitReverseGeocoderDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@interface TwitbitReverseGeocoder :
    NSObject <AsynchronousNetworkFetcherDelegate>
{
    id<TwitbitReverseGeocoderDelegate> delegate;

    CLLocationCoordinate2D coordinate;
    BOOL querying;
    BOOL canceled;
}

@property (nonatomic, assign) id<TwitbitReverseGeocoderDelegate> delegate;
@property (nonatomic, readonly, getter=isQuerying) BOOL querying;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

- (void)start;
- (void)cancel;

@end
