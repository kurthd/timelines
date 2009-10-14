//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKMapView.h>
#import "Geocoder.h"
#import "GeocoderDelegate.h"
#import "BasicMapAnnotation.h"

@interface TweetLocationCellView :
    UIView <MKReverseGeocoderDelegate, MKMapViewDelegate>
{
    CLLocation * location;

    BOOL highlighted;
    MKReverseGeocoder * reverseGeocoder;
    MKMapView * mapView;
    UIActivityIndicatorView * activityIndicator;
    BasicMapAnnotation * mapAnnotation;
    NSString * locationDescription;
    UIColor * textColor;
    double mapSpan;
    BOOL landscape;
    BOOL loading;
}

@property (nonatomic, retain) CLLocation * location;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;
@property (nonatomic, retain) UIColor * textColor;

@end
