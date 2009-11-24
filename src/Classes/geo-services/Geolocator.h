//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@protocol GeolocatorDelegate;

//
// This class provides a simple mechanism for finding the current location,
// including reverse-geocode information for that location.
//
// It will continue to provide its delegate with location updates as the
// hardware continues to refine its coordinates.
//
@interface Geolocator :
    NSObject <CLLocationManagerDelegate, MKReverseGeocoderDelegate>
{
    id<GeolocatorDelegate> delegate;

    CLLocationManager * locationManager;
    MKReverseGeocoder * reverseGeocoder;
}

@property (nonatomic, assign) id<GeolocatorDelegate> delegate;

- (id)init;

- (void)startLocating;
- (void)stopLocating;

@end


@protocol GeolocatorDelegate

- (void)geolocator:(Geolocator *)locator
 didUpdateLocation:(CLLocationCoordinate2D)coordinate
         placemark:(MKPlacemark *)placemark;
- (void)geolocator:(Geolocator *)locator didFailWithError:(NSError *)error;

@end
