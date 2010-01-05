//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "Geolocator.h"
#import "CoordRecentHistoryCache.h"

@interface Geolocator ()
@property (nonatomic, retain) CLLocationManager * locationManager;
@property (nonatomic, retain) TwitbitReverseGeocoder * reverseGeocoder;
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

    [self.reverseGeocoder cancel];
    self.reverseGeocoder =
        [[TwitbitReverseGeocoder alloc]
        initWithCoordinate:[newLocation coordinate]];

    [self.reverseGeocoder setDelegate:self];

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

#pragma mark TwitbitReverseGeocoderDelegate implementation

- (void)reverseGeocoder:(TwitbitReverseGeocoder *)geocoder
       didFindPlacemark:(MKPlacemark *)placemark
{
    CLLocationCoordinate2D coordinate = [self.reverseGeocoder coordinate];
    if (geocoder) { // not from the cache
        CoordRecentHistoryCache * coordCache =
            [CoordRecentHistoryCache instance];
        CLLocation * cacheLocation =
            [[[CLLocation alloc]
            initWithLatitude:coordinate.latitude longitude:coordinate.longitude]
            autorelease];
        [coordCache setObject:placemark forKey:cacheLocation];
    }

    [self.delegate geolocator:self didUpdateLocation:coordinate
        placemark:placemark];
}

- (void)reverseGeocoder:(TwitbitReverseGeocoder *)geocoder
       didFailWithError:(NSError *)error
{
    [self.delegate geolocator:self didFailWithError:error];
}

@end
