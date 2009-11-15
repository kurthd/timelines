//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ActionButtonCellView.h"
#import "UIColor+TwitchColors.h"
#import "SettingsReader.h"

@implementation ActionButtonCellView

@synthesize actionImage, landscape, highlighted;

- (void)dealloc
{
    [actionText release];
    [actionImage release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)aBackgroundColor
{
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
		self.backgroundColor = aBackgroundColor;
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

- (void)setActionText:(NSString *)at
{
    NSString * atCopy = [at copy];
    [actionText release];
    actionText = atCopy;

    [self setNeedsDisplay];
}

- (void)setActionImage:(UIImage *)anActionImage
{
    [anActionImage retain];
    [actionImage release];
    actionImage = anActionImage;

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
#define TOP_MARGIN 4
#define LEFT_MARGIN 5

#define ROUNDED_CORNER_RADIUS 4
#define ACTION_IMAGE_WIDTH 33
#define ACTION_IMAGE_HEIGHT 27

    UIColor * actionTextColor =
        self.highlighted || [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor whiteColor] : [UIColor blackColor];
    UIFont * actionTextFont = [UIFont boldSystemFontOfSize:17];

    [actionTextColor set];
    CGPoint point = CGPointMake(48, 7);
    [actionText drawAtPoint:point withFont:actionTextFont];

    CGRect actionImageRect =
        CGRectMake(TOP_MARGIN, LEFT_MARGIN, ACTION_IMAGE_WIDTH,
        ACTION_IMAGE_HEIGHT);
    [actionImage drawInRect:actionImageRect];
}

@end
