//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "TweetLocationCellView.h"
#import "UIImage+DrawingAdditions.h"
#import "UIColor+TwitchColors.h"
#import "RegexKitLite.h"
#import "SettingsReader.h"
#import "CoordRecentHistoryCache.h"

@interface TweetLocationCellView ()

@property (nonatomic, retain) TwitbitReverseGeocoder * reverseGeocoder;
@property (nonatomic, readonly) MKMapView * mapView;
@property (nonatomic, readonly) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, readonly) BasicMapAnnotation * mapAnnotation;
@property (nonatomic, copy) NSString * locationDescription;

- (void)updateMapSpan;

+ (NSString *)updateLabelText;
+ (NSString *)locationAsString:(CLLocation *)location;

@end

@implementation TweetLocationCellView

#define MAP_WIDTH 86
#define MAP_HEIGHT 48

@synthesize location, highlighted, reverseGeocoder, landscape,
    locationDescription, textColor;

- (void)dealloc
{
    [location release];
    [reverseGeocoder release];
    [mapView release];
    [activityIndicator release];
    [mapAnnotation release];
    [textColor release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
		
        [self addSubview:self.activityIndicator];
	}

	return self;
}

- (void)setHighlighted:(BOOL)lit {
	if (highlighted != lit) {
		highlighted = lit;
		[self setNeedsDisplay];
	}
}

- (void)setLandscape:(BOOL)l
{
    if (landscape != l) {
        landscape = l;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
#define LEFT_MARGIN 2
#define TOP_MARGIN 2
#define LABEL_WIDTH 167
#define LABEL_WIDTH_LANDSCAPE 327
#define LABEL_HEIGHT 50

#define LOCATION_LABEL_LEFT_MARGIN 103
#define LOCATION_LABEL_TOP_MARGIN 27

#define ROUNDED_CORNER_RADIUS 6

    UIColor * locationTextLabelColor = nil;
    UIFont * locationTextLabelFont = [UIFont boldSystemFontOfSize:17];
    
    locationTextLabelColor =
        self.highlighted ? [UIColor whiteColor] : self.textColor;

    CGRect contentRect = self.bounds;

    CGFloat boundsX = contentRect.origin.x;

    CGFloat roundedCornerWidth = ROUNDED_CORNER_RADIUS * 2 + 1;
    CGFloat roundedCornerHeight = ROUNDED_CORNER_RADIUS * 2 + 1;

    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor * darkColor =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor blackColor] : [UIColor twitchDarkGrayColor];
    UIColor * rectColor =
        self.highlighted ? [UIColor whiteColor] : darkColor;

    CGContextSetFillColorWithColor(context, [rectColor CGColor]);

    CGContextFillRect(context,
        CGRectMake(ROUNDED_CORNER_RADIUS + LEFT_MARGIN, TOP_MARGIN,
        MAP_WIDTH + 2 - roundedCornerWidth, MAP_HEIGHT + 2));
    
    // Draw rounded corners
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN, TOP_MARGIN, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN,
        MAP_HEIGHT + 2 + TOP_MARGIN - roundedCornerHeight, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillRect(context,
        CGRectMake(LEFT_MARGIN, TOP_MARGIN + 1 + roundedCornerHeight / 2,
        roundedCornerWidth, MAP_HEIGHT  + 1 - roundedCornerHeight));
        
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN + 2 + MAP_WIDTH - roundedCornerWidth,
        TOP_MARGIN, roundedCornerWidth, roundedCornerHeight));
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN + 2 + MAP_WIDTH - roundedCornerWidth,
        MAP_HEIGHT + 2 + TOP_MARGIN - roundedCornerHeight, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillRect(context,
        CGRectMake(LEFT_MARGIN + 2 + MAP_WIDTH - roundedCornerWidth,
        TOP_MARGIN + 1 + roundedCornerHeight / 2, roundedCornerWidth,
        MAP_HEIGHT - roundedCornerHeight));

    if (!loading) {
        CGFloat labelWidth =
            !landscape ? LABEL_WIDTH : LABEL_WIDTH_LANDSCAPE;
        [locationTextLabelColor set];
        CGSize maxLabelSize = CGSizeMake(labelWidth, LABEL_HEIGHT);
        CGSize size =
            [self.locationDescription sizeWithFont:locationTextLabelFont
            constrainedToSize:maxLabelSize
            lineBreakMode:UILineBreakModeTailTruncation];

        CGRect drawingRect =
            CGRectMake(boundsX + LOCATION_LABEL_LEFT_MARGIN,
            LOCATION_LABEL_TOP_MARGIN - size.height / 2, size.width, size.height);

        [self.locationDescription drawInRect:drawingRect
            withFont:locationTextLabelFont
            lineBreakMode:UILineBreakModeTailTruncation];

        UIGraphicsBeginImageContext(self.mapView.bounds.size);
        [self.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage * viewImage = UIGraphicsGetImageFromCurrentImageContext();
        [viewImage retain]; // Hack: not sure why, but this needs to be retained
        UIGraphicsEndImageContext();
        
        CGRect mapViewRect =
            CGRectMake(TOP_MARGIN + 1, LEFT_MARGIN + 1, MAP_WIDTH, MAP_HEIGHT);
        [viewImage drawInRect:mapViewRect
            withRoundedCornersWithRadius:ROUNDED_CORNER_RADIUS];

        [self.activityIndicator stopAnimating];
    } else
        [self.activityIndicator startAnimating];
}

#pragma mark TwitbitReverseGeocoderDelegate implementation

- (void)reverseGeocoder:(TwitbitReverseGeocoder *)geocoder
    didFindPlacemark:(MKPlacemark *)placemark
{
    NSLog(@"Setting map location description");
    NSLog(@"Placemark address dict: %@", placemark.addressDictionary);
    [self updateMapSpan];
    loading = NO;

    NSString * administrativeArea =
        placemark.administrativeArea ? placemark.administrativeArea :
        placemark.country;
    self.locationDescription =
        placemark.locality ?
        [NSString stringWithFormat:@"%@, %@", placemark.locality,
        administrativeArea] :
        administrativeArea;

    [self setNeedsDisplay];

    if (geocoder) { // not from the cache
        CoordRecentHistoryCache * coordCache =
            [CoordRecentHistoryCache instance];
        [coordCache setObject:placemark forKey:self.location];
    }
}

- (void)reverseGeocoder:(TwitbitReverseGeocoder *)geocoder
    didFailWithError:(NSError *)error
{
    NSLog(@"Failed to reverse geocode coordinate; %@", error);
    loading = NO;
    self.locationDescription = [[self class] locationAsString:self.location];
    [activityIndicator stopAnimating];
    [self setNeedsDisplay];
}

#pragma mark MKMapViewDelegate implementation

- (void)mapViewDidFinishLoadingMap:(MKMapView *)aMapView
{
    NSLog(@"Finished loading map");
    [self setNeedsDisplay];
}

#pragma mark LocationCellView implementation

- (void)setLocation:(CLLocation *)l
{
    NSLog(@"Setting location text on cell view: %@", self);

    [l retain];
    [location release];
    location = l;

    loading = YES;

    [self updateMapSpan];

    CLLocationCoordinate2D coord = l.coordinate;

    [self.reverseGeocoder cancel];
    self.reverseGeocoder =
        [[[TwitbitReverseGeocoder alloc] initWithCoordinate:coord] autorelease];
    self.reverseGeocoder.delegate = self;
    CoordRecentHistoryCache * coordCache = [CoordRecentHistoryCache instance];
    MKPlacemark * cachedPlacemark = [coordCache objectForKey:l];
    if (!cachedPlacemark)
        [self.reverseGeocoder start];
    else {
        NSLog(@"Using placemark from cache");
        [self reverseGeocoder:nil didFindPlacemark:cachedPlacemark];
    }

    [self.mapView setCenterCoordinate:coord animated:NO];
    self.mapAnnotation.coordinate = coord;

    // force map to display, otherwise it won't really update the center
    // and we need to update the location text
    [self setNeedsDisplay];
}

- (void)updateMapSpan
{
    MKCoordinateRegion region = self.mapView.region;
    MKCoordinateSpan span;
    span.latitudeDelta = .002;
    region.span = span;
    self.mapView.region = region;
}

- (MKMapView *)mapView
{
    if (!mapView) {
        CGRect frame = CGRectMake(0, 0, MAP_WIDTH * 1.8, MAP_HEIGHT * 1.8);
        mapView = [[MKMapView alloc] initWithFrame:frame];
        mapView.delegate = self;
        [mapView addAnnotation:self.mapAnnotation];
    }

    return mapView;
}

- (UIActivityIndicatorView *)activityIndicator
{
    if (!activityIndicator) {
        activityIndicator =
            [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicator.hidesWhenStopped = YES;
        CGRect activityIndicatorFrame = activityIndicator.frame;
        activityIndicatorFrame.origin.x = 35;
        activityIndicatorFrame.origin.y = 18;
        activityIndicator.frame = activityIndicatorFrame;
    }

    return activityIndicator;
}

- (BasicMapAnnotation *)mapAnnotation
{
    if (!mapAnnotation)
        mapAnnotation = [[BasicMapAnnotation alloc] init];

    return mapAnnotation;
}

+ (NSString *)updateLabelText
{
    return @"Last location update:";
}

+ (NSString *)locationAsString:(CLLocation *)location
{
    return [NSString stringWithFormat:@"Coord: %f,\n%f",
        location.coordinate.latitude, location.coordinate.longitude];
}

@end
