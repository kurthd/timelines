//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ComposeMapViewController.h"
#import "TwitbitShared.h"
#import "BasicMapAnnotation.h"

@interface ComposeMapViewController ()
- (void)centerViewOnCoordinate:(CLLocationCoordinate2D)coord;
@end

@implementation ComposeMapViewController

@synthesize delegate;

- (void)dealloc
{
    self.delegate = nil;

    [mapView release];
    if (coordinate)
        free(coordinate);

    [super dealloc];
}

- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)bundle
{
    if (self = [super initWithNibName:name bundle:bundle])
        coordinate = NULL;

    return self;
}

#pragma mark Public implementation

- (void)setCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
                   animated:(BOOL)animated
{
    [mapView setCenterCoordinate:aCoordinate animated:animated];
}

#pragma mark UIViewController overrides

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = LS(@"composelocationmapview.title");

    UIBarButtonItem * doneButton =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(userIsDone:)];
    [self.navigationItem setRightBarButtonItem:doneButton animated:NO];
    [doneButton release];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (coordinate)
        [self centerViewOnCoordinate:*coordinate];
}

#pragma mark Button actions

- (void)userIsDone:(id)sender
{
    [self.delegate composeMapViewControllerShouldDismiss:self];
}

#pragma mark MKMapViewDelegate implementation

- (void)mapView:(MKMapView *)mv regionDidChangeAnimated:(BOOL)animated
{
    NSLog(@"map view region changed: %d", animated);

    if (mapView.annotations.count == 0) {
        BasicMapAnnotation * annotation = [[BasicMapAnnotation alloc] init];
        annotation.coordinate = *coordinate;
        annotation.title = nil;
        annotation.subtitle = nil;
        [mapView addAnnotation:annotation];
        [annotation release];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (annotation == mapView.userLocation)
        return nil;

    MKPinAnnotationView * pinAnnotationView =
        [[MKPinAnnotationView alloc]
        initWithAnnotation:[mapView.annotations lastObject]
        reuseIdentifier:@""];
    pinAnnotationView.canShowCallout = NO;
    pinAnnotationView.animatesDrop = YES;

    return [pinAnnotationView autorelease];
}

#pragma mark Private implementation

- (void)centerViewOnCoordinate:(CLLocationCoordinate2D)coord
{
    [mapView setCenterCoordinate:coord animated:YES];

    MKCoordinateSpan span = { 0.5, 0.5 };
    MKCoordinateRegion region = { coord, span };

    [mapView setRegion:region animated:YES];
}

@end


@implementation ComposeMapViewController (InstantiationHelpers)

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)aCoordinate
                      delegate:(id<ComposeMapViewControllerDelegate>)aDelegate;
{
    if (self = [self initWithNibName:@"ComposeMapView" bundle:nil]) {
        self.delegate = aDelegate;

        coordinate =
            (CLLocationCoordinate2D *) malloc(sizeof(CLLocationCoordinate2D));
        memcpy(coordinate, &aCoordinate, sizeof(CLLocationCoordinate2D));
    }

    return self;
}

@end
