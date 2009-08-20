//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@class Geocoder;

@protocol GeocoderDelegate

- (void)geocoder:(Geocoder *)coder
    didFindCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)geocoder:(Geocoder *)coder didFailWithError:(NSError *)error;
- (void)unableToFindCoordinatesWithGeocoder:(Geocoder *)coder;

@end
