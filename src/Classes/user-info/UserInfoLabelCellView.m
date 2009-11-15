//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserInfoLabelCellView.h"
#import "UIColor+TwitchColors.h"
#import "SettingsReader.h"

@implementation UserInfoLabelCellView

@synthesize highlighted;

- (void)dealloc
{
    [keyText release];
    [valueText release];
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

- (void)setKeyText:(NSString *)kt valueText:(NSString *)vt
{
    NSString * tempKeyText = [kt copy];
    [keyText release];
    keyText = tempKeyText;

    NSString * tempValueText = [vt copy];
    [valueText release];
    valueText = tempValueText;

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
#define KEY_LABEL_WIDTH 89
#define KEY_RIGHT_MARGIN 183
#define KEY_TOP_MARGIN 8
#define KEY_FONT_SIZE 15.4

#define VALUE_LABEL_WIDTH 188
#define VALUE_LEFT_MARGIN 102
#define VALUE_TOP_MARGIN 7
#define VALUE_FONT_SIZE 19

    UIColor * keyLabelTextColor = nil;
    UIFont * keyLabelFont = [UIFont boldSystemFontOfSize:KEY_FONT_SIZE];

	UIColor * valueLabelTextColor = nil;
	UIFont * valueLabelFont = [UIFont boldSystemFontOfSize:VALUE_FONT_SIZE];

    if (self.highlighted) {
		keyLabelTextColor = [UIColor whiteColor];
		valueLabelTextColor = [UIColor whiteColor];
	} else if ([SettingsReader displayTheme] == kDisplayThemeDark) {
	    keyLabelTextColor = [UIColor twitchBlueOnDarkBackgroundColor];
		valueLabelTextColor = [UIColor whiteColor];
	} else {
        keyLabelTextColor = [UIColor twitchLabelColor];
		valueLabelTextColor = [UIColor blackColor];
	}

	CGRect contentRect = self.bounds;
	CGFloat boundsX = contentRect.origin.x;
    CGPoint point;

    [keyLabelTextColor set];
    CGSize size = [keyText sizeWithFont:keyLabelFont];
    point =
        CGPointMake(
        (contentRect.origin.x +
        /* contentRect.size.width (for landscape)*/ 273) -
        KEY_RIGHT_MARGIN - size.width,
        KEY_TOP_MARGIN);
    [keyText drawAtPoint:point withFont:keyLabelFont];

    [valueLabelTextColor set];
	point = CGPointMake(boundsX + VALUE_LEFT_MARGIN, VALUE_TOP_MARGIN);
	[valueText drawAtPoint:point forWidth:VALUE_LABEL_WIDTH
	    withFont:valueLabelFont minFontSize:VALUE_FONT_SIZE
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
}

@end
