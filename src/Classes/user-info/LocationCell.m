//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "LocationCell.h"

@implementation LocationCell

- (void)dealloc
{
    [locationCellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {

	if (self = [super initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:reuseIdentifier]) {

        CGRect cellViewFrame =
            CGRectMake(5.0, 5.0, self.contentView.bounds.size.width - 10.0,
            self.contentView.bounds.size.height - 10.0);
        locationCellView =
            [[LocationCellView alloc] initWithFrame:cellViewFrame];
        locationCellView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:locationCellView];
	}

	return self;
}

// - (void)awakeFromNib
// {
//     [super awakeFromNib];
//     mapView.delegate = self;
//     
//     MKCoordinateRegion region = mapView.region;
//     CLLocationCoordinate2D coordinate;
//     coordinate.longitude = -122.419209;
//     coordinate.latitude = 37.775206;
//     region.center = coordinate;
//     MKCoordinateSpan span;
//     span.latitudeDelta = .002;
//     span.longitudeDelta = .002;
//     region.span = span;
//     [mapView setRegion:region animated:YES];
// }

- (void)setLocationText:(NSString *)locationText
{
    // mapView.delegate = self;
    // NSLog(@"Setting map view coordinates");
    // NSLog(@"Map view: %@", mapView);
    // NSLog(@"coordinate long: %f", coordinate.longitude);
    // NSLog(@"coordinate lat: %f", coordinate.latitude);
    // MKCoordinateRegion region = mapView.region;
    // region.center = coordinate;
    // MKCoordinateSpan span;
    // span.latitudeDelta = .005;
    // span.longitudeDelta = .005;
    // region.span = span;
    // [mapView setRegion:region animated:YES];
    //[mapView setCenterCoordinate:coordinate animated:YES];
    [locationCellView setLocationText:locationText];
}

- (void)redisplay {
	[locationCellView setNeedsDisplay];
}

@end
