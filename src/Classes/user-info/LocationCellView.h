//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKMapView.h>
#import "Geocoder.h"
#import "GeocoderDelegate.h"
#import "BasicMapAnnotation.h"

@interface LocationCellView : UIView <GeocoderDelegate, MKMapViewDelegate>
{
    NSString * locationText;

    BOOL highlighted;
    Geocoder * geocoder;
    MKMapView * mapView;
    UIActivityIndicatorView * activityIndicator;
    BOOL updatingMap;
    BasicMapAnnotation * mapAnnotation;
    UIColor * textColor;

    double mapSpan;

    BOOL landscape;
}

@property (nonatomic, copy) NSString * locationText;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;
@property (nonatomic, retain) UIColor * textColor;

@end
