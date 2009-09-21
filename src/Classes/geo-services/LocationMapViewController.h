//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKMapView.h>
#import "Geocoder.h"
#import "GeocoderDelegate.h"
#import "BasicMapAnnotation.h"
#import "LocationMapViewControllerDelegate.h"

@interface LocationMapViewController :
    UIViewController <GeocoderDelegate, MKMapViewDelegate>
{
    id<LocationMapViewControllerDelegate> delegate;

    IBOutlet MKMapView * mapView;
    Geocoder * geocoder;
    BOOL updatingMap;
    BasicMapAnnotation * mapAnnotation;
    MKAnnotationView * mapAnnotationView;
    double mapSpan;
    BOOL setUserLocationButton;
    UIBarButtonItem * userLocationButton;
    UIBarButtonItem * activityIndicator;
    BOOL showingUserLocation;
    BOOL didAddUserLocationAnnotation;
}

@property (nonatomic, assign) id<LocationMapViewControllerDelegate> delegate;

- (void)setLocation:(NSString *)location;
- (void)setCurrentLocation:(UIBarButtonItem *)sender;

- (IBAction)handleSegmentSelection:(id)sender;

@end
