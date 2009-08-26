//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LocationMapViewControllerDelegate

- (void)showLocationInfo:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate;

@end
