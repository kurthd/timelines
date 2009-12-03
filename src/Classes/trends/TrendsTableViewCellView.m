//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendsTableViewCellView.h"

@interface TrendsTableViewCellView ()
- (UIColor *)titleColor;
- (UIColor *)explanationColor;
@end

@implementation TrendsTableViewCellView

@synthesize highlighted, title, explanation;

- (void)dealloc
{
    self.title = nil;
    self.explanation = nil;

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

#pragma mark Public implementation

- (void)setHighlighted:(BOOL)b
{
    if (highlighted != b) {
        highlighted = b;
        [self setNeedsDisplay];
    }
}

- (void)setTitle:(NSString *)aTitle
{
    if (![title isEqualToString:aTitle]) {
        [title release];
        title = [aTitle copy];
        [self setNeedsDisplay];
    }
}

- (void)setExplanation:(NSString *)anExplanation
{
    if (![explanation isEqualToString:anExplanation]) {
        [explanation release];
        explanation = [anExplanation copy];
        [self setNeedsDisplay];
    }
}

+ (CGFloat)heightForTitle:(NSString *)title explanation:(NSString *)explanation
{
    return 69.0;
}

#pragma mark UIView overrides

- (void)drawRect:(CGRect)rect
{
    static const CGFloat LEFT_MARGIN = 5.0;
    static const CGFloat TOP_MARGIN = 4.0;
    static const CGFloat ELEMENT_SPACE = 1.0;
    static const CGFloat EXPLANATION_HEIGHT = 40.0;

    CGPoint point;
    CGSize size;

    UIFont * titleFont = [UIFont boldSystemFontOfSize:18.0];
    UIFont * explanationFont = [UIFont systemFontOfSize:14.0];

    [[self titleColor] set];
    size = [title sizeWithFont:titleFont];
    point = CGPointMake(LEFT_MARGIN, TOP_MARGIN);

    [title drawAtPoint:point
              forWidth:size.width
              withFont:titleFont
              fontSize:titleFont.pointSize
         lineBreakMode:UILineBreakModeTailTruncation
    baselineAdjustment:UIBaselineAdjustmentNone];

    [[self explanationColor] set];
    point = CGPointMake(LEFT_MARGIN, TOP_MARGIN + size.height + ELEMENT_SPACE);
    CGSize explanationSize = CGSizeMake(
        self.bounds.size.width - LEFT_MARGIN * 2, EXPLANATION_HEIGHT);

    CGRect explanationRect =
        CGRectMake(
            point.x,
            point.y,
            explanationSize.width,
            explanationSize.height);

    [explanation drawInRect:explanationRect
                   withFont:explanationFont
              lineBreakMode:UILineBreakModeTailTruncation];
}

#pragma mark Private implementation

- (UIColor *)titleColor
{
    return highlighted ? [UIColor whiteColor] : [UIColor blackColor];
}

- (UIColor *)explanationColor
{
    return highlighted ? [UIColor whiteColor] : [UIColor grayColor];
}

@end
