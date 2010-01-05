//
//  Copyright 2010 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKPlacemark.h>

@class TwitbitReverseGeocoder;

@protocol TwitbitReverseGeocoderDelegate

- (void)reverseGeocoder:(TwitbitReverseGeocoder *)coder
    didFindPlacemark:(MKPlacemark *)placemark;
- (void)reverseGeocoder:(TwitbitReverseGeocoder *)coder
    didFailWithError:(NSError *)error;

@end
