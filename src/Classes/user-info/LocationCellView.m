//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "LocationCellView.h"
#import "UIImage+DrawingAdditions.h"
#import "UIColor+TwitchColors.h"
#import "RegexKitLite.h"
#import "SettingsReader.h"
#import "AsynchronousNetworkFetcher.h"
#import "RegexKitLite.h"

@interface LocationCellView ()

@property (nonatomic, readonly) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain) UIImage * mapImage;
@property (nonatomic, retain) AsynchronousNetworkFetcher * impageUrlFetcher;

+ (NSString *)updateLabelText;

@end

@implementation LocationCellView

#define MAP_WIDTH 86
#define MAP_HEIGHT 48

@synthesize locationText, highlighted, landscape, textColor, mapImage,
    impageUrlFetcher;

- (void)dealloc
{
    [locationText release];
    [activityIndicator release];
    [textColor release];
    [impageUrlFetcher release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
        [self addSubview:self.activityIndicator];
        self.textColor = [UIColor blackColor];
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
    
    if (self.highlighted)
        locationTextLabelColor = [UIColor whiteColor];
    else
        locationTextLabelColor = self.textColor;

    CGRect contentRect = self.bounds;

    CGFloat boundsX = contentRect.origin.x;

    CGFloat labelWidth =
        !landscape ? LABEL_WIDTH : LABEL_WIDTH_LANDSCAPE;
    [locationTextLabelColor set];
    CGSize maxLabelSize = CGSizeMake(labelWidth, LABEL_HEIGHT);
    CGSize size =
        [self.locationText sizeWithFont:locationTextLabelFont
        constrainedToSize:maxLabelSize
        lineBreakMode:UILineBreakModeTailTruncation];

    CGRect drawingRect =
        CGRectMake(boundsX + LOCATION_LABEL_LEFT_MARGIN,
        LOCATION_LABEL_TOP_MARGIN - size.height / 2, size.width, size.height);

    [self.locationText drawInRect:drawingRect withFont:locationTextLabelFont
        lineBreakMode:UILineBreakModeTailTruncation];

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

    if (!updatingMap) {
        CGRect mapViewRect =
            CGRectMake(TOP_MARGIN + 1, LEFT_MARGIN + 1, MAP_WIDTH, MAP_HEIGHT);
        [mapImage drawInRect:mapViewRect
            withRoundedCornersWithRadius:ROUNDED_CORNER_RADIUS];
        
        [self.activityIndicator stopAnimating];
    } else
        [self.activityIndicator startAnimating];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    if (fetcher == self.impageUrlFetcher) {
        NSString * mapResponse =
            [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString * mapUrlString =
            [mapResponse stringByMatching:@">(http://.*)<" capture:1];
        if (mapUrlString) {
            NSURL * mapUrl = [NSURL URLWithString:mapUrlString];
            [AsynchronousNetworkFetcher fetcherWithUrl:mapUrl delegate:self];
        } else {
            updatingMap = NO;
            [self setNeedsDisplay];
        }
    } else {
        self.mapImage = [UIImage imageWithData:data];
        updatingMap = NO;
        [self setNeedsDisplay];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    updatingMap = NO;
    [self setNeedsDisplay];
}

#pragma mark LocationCellView implementation

- (void)setLocationText:(NSString *)lt
{
    NSLog(@"Setting location text on cell view: %@", self);
    NSString * tempLocationText = [lt copy];
    [locationText release];
    locationText = tempLocationText;
    
    updatingMap = YES;
    NSString * locationSearchString =
        [lt stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString * mapRequest =
        [NSString stringWithFormat:@"http://local.yahooapis.com/MapsService/V1/mapImage?appid=C6jk31jV34FnMBsiQ3kq0a8vVPX7P3WKQhihvCytcAuNrRI9LhgSVDu2K_.0_FTWOw--&location=%@&radius=200&image_height=96&image_width=172", locationSearchString];
    NSURL * url = [NSURL URLWithString:mapRequest];
    self.impageUrlFetcher =
        [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];
    
    // force map to display, otherwise it won't really update the center
    // and we need to update the location text
    [self setNeedsDisplay];
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

+ (NSString *)updateLabelText
{
    return @"Last location update:";
}

@end