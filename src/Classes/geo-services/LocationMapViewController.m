//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "LocationMapViewController.h"
#import "RegexKitLite.h"
#import "SettingsReader.h"

@interface LocationMapViewController ()

@property (nonatomic, retain) Geocoder * geocoder;
@property (nonatomic, readonly) BasicMapAnnotation * mapAnnotation;
@property (nonatomic, readonly) MKAnnotationView * mapAnnotationView;
@property (nonatomic, readonly) UIBarButtonItem * activityIndicator;
@property (nonatomic, retain) UIBarButtonItem * userLocationButton;

- (void)updateMapSpan;
- (void)showLocationInfo;

+ (BOOL)location:(CLLocationCoordinate2D)loc1
    equalsLocation:(CLLocationCoordinate2D)loc2;

@end

@implementation LocationMapViewController

@synthesize delegate;
@synthesize geocoder, userLocationButton;

- (void)dealloc
{
    [mapView release];
    [mapToolbar release];
    [mapSegmentedControl release];
    [geocoder release];
    [mapAnnotation release];
    [mapAnnotationView release];
    [activityIndicator release];
    [userLocationButton release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        mapToolbar.barStyle = UIBarStyleBlackOpaque;
        mapSegmentedControl.tintColor = [UIColor blackColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!setUserLocationButton) {
        setUserLocationButton = YES;
        self.userLocationButton = self.navigationItem.rightBarButtonItem;
    }
}

#pragma mark GeocoderDelegate implementation

- (void)geocoder:(Geocoder *)coder
    didFindCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Setting map coordinates");
    if ([[self class] location:mapView.centerCoordinate
        equalsLocation:coordinate])
        [mapView addAnnotation:self.mapAnnotation];
    [self updateMapSpan];
    updatingMap = NO;
    [mapView setCenterCoordinate:coordinate animated:NO];
    self.mapAnnotation.coordinate = coordinate;
    mapView.showsUserLocation = showingUserLocation;
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
        nil : self.mapAnnotationView;
}

- (void)mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views
{
    for (MKAnnotationView * view in views) {
        if (view.annotation == mapView.userLocation) {
            didAddUserLocationAnnotation = YES;
            [mapView setCenterCoordinate:view.annotation.coordinate
                animated:YES];
            self.navigationItem.rightBarButtonItem = userLocationButton;
            // just make sure the state is consistent
            userLocationButton.style = UIBarButtonItemStyleDone;
            break;
        }
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)aMapView
{
    self.navigationItem.rightBarButtonItem = self.userLocationButton;
}

- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated
{
    [mapView addAnnotation:self.mapAnnotation];
}

#pragma mark LocationMapViewController public implementation

- (void)setLocation:(NSString *)locationText
{
    NSLog(@"Setting location to %@", locationText);
    
    self.mapAnnotation.title = locationText;

    [mapView removeAnnotation:self.mapAnnotation];

    showingUserLocation = NO;
    didAddUserLocationAnnotation = NO;
    mapView.showsUserLocation = NO;
    if (self.userLocationButton)
        self.navigationItem.rightBarButtonItem = self.userLocationButton;
    self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleBordered;

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
        if ([[self class] location:mapView.centerCoordinate
            equalsLocation:coord])
            [mapView addAnnotation:self.mapAnnotation];
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

- (void)showLocationInfo
{
    [delegate showLocationInfo:self.mapAnnotation.title
        coordinate:self.mapAnnotation.coordinate];
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
        UIButton * disclosureButton =
            [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [disclosureButton addTarget:self action:@selector(showLocationInfo)
            forControlEvents:UIControlEventTouchUpInside];
        pinAnnotationView.rightCalloutAccessoryView = disclosureButton;
        pinAnnotationView.animatesDrop = YES;

        mapAnnotationView = pinAnnotationView;
    }

    return mapAnnotationView;
}

- (void)setCurrentLocation:(UIBarButtonItem *)sender
{
    showingUserLocation = !showingUserLocation;
    mapView.showsUserLocation = showingUserLocation;
    sender.style = showingUserLocation ?
        UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
    if (showingUserLocation && !didAddUserLocationAnnotation)
        self.navigationItem.rightBarButtonItem = self.activityIndicator;
}

- (UIBarButtonItem *)activityIndicator
{
    if (!activityIndicator) {
        NSString * backgroundImageFilename =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            @"NavigationButtonBackgroundDarkTheme.png" :
            @"NavigationButtonBackground.png";
        UIView * view =
            [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:backgroundImageFilename]];
        UIActivityIndicatorView * activityView =
            [[[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]
            autorelease];
        activityView.frame = CGRectMake(7, 5, 20, 20);
        [view addSubview:activityView];

        activityIndicator =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [activityView startAnimating];

        [view release];
    }

    return activityIndicator;
}

+ (BOOL)location:(CLLocationCoordinate2D)loc1
    equalsLocation:(CLLocationCoordinate2D)loc2
{
    return loc1.longitude == loc2.longitude && loc1.latitude == loc2.latitude;
}

@end
