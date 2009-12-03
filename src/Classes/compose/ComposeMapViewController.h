//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol ComposeMapViewControllerDelegate;

@interface ComposeMapViewController : UIViewController <MKMapViewDelegate>
{
    id<ComposeMapViewControllerDelegate> delegate;

    IBOutlet MKMapView * mapView;
    CLLocationCoordinate2D * coordinate;
}

@property (nonatomic, assign) id<ComposeMapViewControllerDelegate> delegate;

@end

@interface ComposeMapViewController (InstantiationHelpers)

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
                      delegate:(id<ComposeMapViewControllerDelegate>)aDelegate;

@end


@protocol ComposeMapViewControllerDelegate

- (void)composeMapViewControllerShouldDismiss:(ComposeMapViewController *)c;

@end
