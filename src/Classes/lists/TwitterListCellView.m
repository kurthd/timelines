//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitterListCellView.h"

@interface TwitterListCellView ()

- (NSString *)followingDescription;

+ (UIImage *)privateIcon;
+ (UIImage *)privateIconHighlighted;

@end

@implementation TwitterListCellView

@synthesize landscape, highlighted;

static UIImage * privateIcon;
static UIImage * privateIconHighlighted;

- (void)dealloc
{
    [list release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];
	}

	return self;
}

- (void)setList:(TwitterList *)aList
{
    [aList retain];
    [list release];
    list = aList;

    [self setNeedsDisplay];
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
#define LEFT_MARGIN 9
#define TOP_MARGIN 3

#define FOLLOWERS_TOP_MARGIN 24

#define LABEL_WIDTH_LANDSCAPE 302
#define LABEL_WIDTH 290

    UIColor * nameLabelTextColor = nil;
    UIFont * nameLabelFont = [UIFont boldSystemFontOfSize:18];

	UIColor * followersLabelTextColor = nil;
	UIFont * followersLabelFont = [UIFont systemFontOfSize:14];

    if (self.highlighted) {
		nameLabelTextColor = [UIColor whiteColor];
		followersLabelTextColor = [UIColor whiteColor];
	} else {
        nameLabelTextColor = [UIColor blackColor];
		followersLabelTextColor = [UIColor grayColor];
	}

	CGRect contentRect = self.bounds;
	CGFloat boundsX = contentRect.origin.x;
    CGFloat labelWidth = landscape ? LABEL_WIDTH_LANDSCAPE : LABEL_WIDTH;

	[nameLabelTextColor set];
	CGPoint point = CGPointMake(boundsX + LEFT_MARGIN, TOP_MARGIN);
	[list.fullName drawAtPoint:point forWidth:labelWidth
	    withFont:nameLabelFont minFontSize:15
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

	[followersLabelTextColor set];
	point = CGPointMake(boundsX + LEFT_MARGIN + 2, FOLLOWERS_TOP_MARGIN);

    NSString * followersString = [self followingDescription];
    [followersString drawAtPoint:point forWidth:labelWidth
	    withFont:followersLabelFont minFontSize:14
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

    if ([list.mode isEqual:@"private"]) {
        CGSize size = [followersString sizeWithFont:followersLabelFont];
    	point =
    	    CGPointMake(boundsX + size.width + 14, FOLLOWERS_TOP_MARGIN + 2);
    	if (highlighted)
	        [[[self class] privateIconHighlighted] drawAtPoint:point];
    	else
	        [[[self class] privateIcon] drawAtPoint:point];
    }
}

- (NSString *)followingDescription
{
    NSString * description;

    NSString * memberCountFormatString =
        NSLocalizedString(@"listsviewcontroller.membercount", @"");
    NSString * memberCountString =
        [NSString stringWithFormat:memberCountFormatString, list.memberCount];
    if ([list.subscriberCount intValue]) {
        NSString * subCountFormatString =
            NSLocalizedString(@"listsviewcontroller.subscribercount", @"");
	    NSString * followersString =
            [NSString stringWithFormat:subCountFormatString,
            list.subscriberCount];

        description =
            [NSString stringWithFormat:@"%@, %@", followersString,
            memberCountString];
    } else
        description = memberCountString;

    return description;
}

+ (UIImage *)privateIcon
{
    if (!privateIcon)
        privateIcon = [[UIImage imageNamed:@"PrivateIcon.png"] retain];

    return privateIcon;
}

+ (UIImage *)privateIconHighlighted
{
    if (!privateIconHighlighted)
        privateIconHighlighted =
            [[UIImage imageNamed:@"PrivateIconHighlighted.png"] retain];

    return privateIconHighlighted;
}

@end
