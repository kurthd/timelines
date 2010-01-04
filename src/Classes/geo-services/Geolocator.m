//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "Geolocator.h"
#import "CoordRecentHistoryCache.h"

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

    CoordRecentHistoryCache * coordCache = [CoordRecentHistoryCache instance];
    MKPlacemark * cachedPlacemark = [coordCache objectForKey:newLocation];
    if (!cachedPlacemark)
        [self.reverseGeocoder start];
    else {
        NSLog(@"Using placemark from cache");
        [self reverseGeocoder:nil didFindPlacemark:cachedPlacemark];
    }
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
    CLLocationCoordinate2D cacheCoord = [self.reverseGeocoder coordinate];
    if (geocoder) { // not from the cache
        CoordRecentHistoryCache * coordCache =
            [CoordRecentHistoryCache instance];
        CLLocation * cacheLocation =
            [[[CLLocation alloc]
            initWithLatitude:cacheCoord.latitude longitude:cacheCoord.longitude]
            autorelease];
        [coordCache setObject:placemark forKey:cacheLocation];
    }

    [self.delegate geolocator:self didUpdateLocation:cacheCoord
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
