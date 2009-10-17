//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "LocationInfoLabelCell.h"
#import "ButtonCell.h"
#import "BasicMapAnnotation.h"
#import "RoundedImage.h"
#import "LocationInfoViewControllerDelegate.h"

@interface LocationInfoViewController :
    UITableViewController
    <UITableViewDelegate, UITableViewDataSource, MKReverseGeocoderDelegate,
    MKMapViewDelegate, UIActionSheetDelegate>
{
    id<LocationInfoViewControllerDelegate> delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIImageView * headerBackgroundView;
    IBOutlet UIImageView * avatarBackgroundView;
    IBOutlet UIView * headerTopLine;
    IBOutlet UIView * headerBottomLine;
    IBOutlet UIView * headerViewPadding;
    IBOutlet UILabel * titleLabel;
    IBOutlet RoundedImage * mapThumbnail;

    LocationInfoLabelCell * addressCell;
    ButtonCell * directionsToCell;
    ButtonCell * directionsFromCell;
    UITableViewCell * searchLocationCell;
    UITableViewCell * nearbyTweetsCell;

    MKReverseGeocoder * reverseGeocoder;

    MKMapView * mapView;
    BasicMapAnnotation * mapAnnotation;

    BOOL foundAddress;
    BOOL streetLevel;
    NSString * street;
    NSString * city;
    NSString * country;
}

@property (nonatomic, assign) id<LocationInfoViewControllerDelegate> delegate;

- (void)setLocationString:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate;
    
@end
