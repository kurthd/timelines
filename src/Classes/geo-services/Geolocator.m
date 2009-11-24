//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "Geolocator.h"

@interface Geolocator ()
@property (nonatomic, retain) CLLocationManager * locationManager;
@property (nonatomic, retain) MKReverseGeocoder * reverseGeocoder;
@end

@implementation Geolocator

@synthesize delegate, locationManager, reverseGeocoder;

- (void)dealloc
{
    self.delegate = nil;

    self.locationManager = nil;
    self.reverseGeocoder = nil;

    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }

    return self;
}

#pragma mark Public implementation

- (void)startLocating
{
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocating
{
    [self.locationManager stopUpdatingLocation];
}

#pragma mark CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // Per Apple's documentation, only allow one reverse geocoder to
    // operate at once.

    if (self.reverseGeocoder) {
        [self.reverseGeocoder cancel];
        self.reverseGeocoder = nil;
    }

    MKReverseGeocoder * geocoder =
        [[MKReverseGeocoder alloc] initWithCoordinate:[newLocation coordinate]];
    [geocoder setDelegate:self];

    self.reverseGeocoder = geocoder;
    [geocoder release];

    [self.reverseGeocoder start];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [self.delegate geolocator:self didFailWithError:error];
}

#pragma mark MKReverseGeocoderDelegate implementation

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder
       didFindPlacemark:(MKPlacemark *)placemark
{
    [self.delegate geolocator:self
            didUpdateLocation:[geocoder coordinate]
                    placemark:placemark];

    if (self.reverseGeocoder == geocoder) {
        [reverseGeocoder autorelease];
        reverseGeocoder = nil;
    }
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder
       didFailWithError:(NSError *)error
{
    [self.delegate geolocator:self didFailWithError:error];

    if (self.reverseGeocoder == geocoder) {
        [reverseGeocoder autorelease];
        reverseGeocoder = nil;
    }
}

@end
