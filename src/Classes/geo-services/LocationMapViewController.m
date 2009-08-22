//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "LocationMapViewController.h"
#import "RegexKitLite.h"

@interface LocationMapViewController ()

@property (nonatomic, retain) Geocoder * geocoder;
@property (nonatomic, readonly) BasicMapAnnotation * mapAnnotation;
@property (nonatomic, readonly) MKAnnotationView * mapAnnotationView;
@property (nonatomic, readonly) MKAnnotationView * userLocationAnnotationView;

- (void)updateMapSpan;

@end

@implementation LocationMapViewController

@synthesize geocoder;

- (void)dealloc
{
    [mapView release];
    [geocoder release];
    [mapAnnotation release];
    [mapAnnotationView release];
    [userLocationAnnotationView release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!addedAnnotation) {
        addedAnnotation = YES;
        [mapView addAnnotation:self.mapAnnotation];
    }
}

#pragma mark GeocoderDelegate implementation

- (void)geocoder:(Geocoder *)coder
    didFindCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Setting map coordinates");
    [self updateMapSpan];
    updatingMap = NO;
    [mapView setCenterCoordinate:coordinate animated:NO];
    self.mapAnnotation.coordinate = coordinate;
}

- (void)geocoder:(Geocoder *)coder didFailWithError:(NSError *)error
{
}

- (void)unableToFindCoordinatesWithGeocoder:(Geocoder *)coder
{
}

#pragma mark MKMapViewDelegate implementation

- (MKAnnotationView *)mapView:(MKMapView *)aMapView
    viewForAnnotation:(id<MKAnnotation>)annotation
{
    return annotation == mapView.userLocation ?
        self.userLocationAnnotationView : self.mapAnnotationView;
}

#pragma mark LocationMapViewController public implementation

- (void)setLocation:(NSString *)locationText
{
    NSLog(@"Setting location to %@", locationText);

    self.mapAnnotation.title = locationText;

    static NSString * coordRegex =
        @"[^[-\\d\\.]]*([-\\d\\.]+\\s*,\\s*[-\\d\\.]+)[^[-\\d\\.]]*";

    BOOL streetLevel = [locationText isMatchedByRegex:coordRegex];
    mapSpan = streetLevel ? .002 : 7.5;

    if (!streetLevel) {
        [self.geocoder cancel];
        self.geocoder =
            [[[Geocoder alloc] initWithQuery:locationText] autorelease];
        self.geocoder.delegate = self;
        [self.geocoder start];
        updatingMap = YES;
    } else {
        [self updateMapSpan];
        NSString * coordinatesAsString =
            [locationText stringByMatching:coordRegex capture:1];
        NSArray * components =
            [coordinatesAsString componentsSeparatedByRegex:@"\\s*,\\s*"];
        CLLocationCoordinate2D coord;
        coord.latitude = [[components objectAtIndex:0] doubleValue];
        coord.longitude = [[components objectAtIndex:1] doubleValue];

        updatingMap = NO;
        [mapView setCenterCoordinate:coord animated:NO];
        self.mapAnnotation.coordinate = coord;
    }
}

- (IBAction)handleSegmentSelection:(id)sender
{
    UISegmentedControl * control = (UISegmentedControl *)sender;
    switch (control.selectedSegmentIndex) {
        case 0:
            mapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            mapView.mapType = MKMapTypeSatellite;
            break;
        case 2:
            mapView.mapType = MKMapTypeHybrid;
            break;
    }
}

#pragma mark LocationMapViewController private implementation

- (void)updateMapSpan
{
    MKCoordinateRegion region = mapView.region;
    MKCoordinateSpan span;
    span.latitudeDelta = mapSpan;
    region.span = span;
    mapView.region = region;
}

- (BasicMapAnnotation *)mapAnnotation
{
    if (!mapAnnotation)
        mapAnnotation = [[BasicMapAnnotation alloc] init];

    return mapAnnotation;
}

- (MKAnnotationView *)mapAnnotationView
{
    if (!mapAnnotationView) {
        MKPinAnnotationView * pinAnnotationView =
            [[MKPinAnnotationView alloc]
            initWithAnnotation:self.mapAnnotation reuseIdentifier:@""];
        pinAnnotationView.canShowCallout = YES;
        pinAnnotationView.rightCalloutAccessoryView =
            [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        mapAnnotationView = pinAnnotationView;
    }

    return mapAnnotationView;
}

- (MKAnnotationView *)userLocationAnnotationView
{
    if (!userLocationAnnotationView) {
        MKPinAnnotationView * pinAnnotationView =
            [[MKPinAnnotationView alloc]
            initWithAnnotation:self.mapAnnotation reuseIdentifier:@""];
        pinAnnotationView.canShowCallout = YES;
        pinAnnotationView.pinColor = MKPinAnnotationColorPurple;
        pinAnnotationView.animatesDrop = YES;
        pinAnnotationView.rightCalloutAccessoryView =
            [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        userLocationAnnotationView = pinAnnotationView;
    }

    return userLocationAnnotationView;
}

- (void)setCurrentLocation:(UIBarButtonItem *)sender
{
    mapView.showsUserLocation = !mapView.showsUserLocation;
    sender.style = mapView.showsUserLocation ?
        UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
}

@end
