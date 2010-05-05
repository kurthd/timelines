//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Geocoder.h"
#import "GeocoderDelegate.h"
#import "TwitbitReverseGeocoder.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "AsynchronousNetworkFetcher.h"

@interface TweetLocationCellView :
    UIView <TwitbitReverseGeocoderDelegate, AsynchronousNetworkFetcherDelegate>
{
    CLLocation * location;
    BOOL highlighted;
    TwitbitReverseGeocoder * reverseGeocoder;
    UIActivityIndicatorView * activityIndicator;
    NSString * locationDescription;
    UIColor * textColor;
    BOOL landscape;
    BOOL loading;
    AsynchronousNetworkFetcher * impageUrlFetcher;
    UIImage * mapImage;
}

@property (nonatomic, retain) CLLocation * location;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;
@property (nonatomic, retain) UIColor * textColor;

@end
