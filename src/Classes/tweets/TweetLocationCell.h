//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MKMapView.h>
#import "TweetLocationCellView.h"

@interface TweetLocationCell : UITableViewCell <MKMapViewDelegate>
{
    TweetLocationCellView * locationCellView;
}

- (void)setLocation:(CLLocation *)location;
- (void)redisplay;
- (void)setLandscape:(BOOL)landscape;
- (void)setLabelTextColor:(UIColor *)color;

@end
