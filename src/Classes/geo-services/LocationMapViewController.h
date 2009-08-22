//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKMapView.h>
#import "Geocoder.h"
#import "GeocoderDelegate.h"
#import "BasicMapAnnotation.h"

@interface LocationMapViewController :
    UIViewController <GeocoderDelegate, MKMapViewDelegate>
{
    IBOutlet MKMapView * mapView;
    Geocoder * geocoder;
    BOOL updatingMap;
    BasicMapAnnotation * mapAnnotation;
    MKAnnotationView * mapAnnotationView;
    MKAnnotationView * userLocationAnnotationView;
    double mapSpan;
    BOOL addedAnnotation;
}

- (void)setLocation:(NSString *)location;
- (void)setCurrentLocation:(UIBarButtonItem *)sender;

- (IBAction)handleSegmentSelection:(id)sender;

@end
