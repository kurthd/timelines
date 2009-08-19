//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeocoderDelegate.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@interface Geocoder : NSObject <AsynchronousNetworkFetcherDelegate>
{
    id<GeocoderDelegate> delegate;

    NSString * query;
    BOOL querying;
    BOOL canceled;
}

@property (nonatomic, assign) id<GeocoderDelegate> delegate;
@property (nonatomic, readonly, getter=isQuerying) BOOL querying;

- (id)initWithQuery:(NSString *)query;

- (void)start;
- (void)cancel;

@end
