//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MKMapView.h>
#import "LocationCellView.h"

@interface LocationCell : UITableViewCell <MKMapViewDelegate>
{
    LocationCellView * locationCellView;
}

- (void)setLocationText:(NSString *)locationText;
- (void)redisplay;
- (void)setLandscape:(BOOL)landscape;

@end
