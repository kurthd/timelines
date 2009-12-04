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
    return 66.0;
}

#pragma mark UIView overrides

- (void)drawRect:(CGRect)rect
{
    static const CGFloat LEFT_MARGIN = 12.0;
    static const CGFloat RIGHT_MARGIN = 3.0;
    static const CGFloat TOP_MARGIN = 3.0;
    static const CGFloat ELEMENT_SPACE = 0.0;
    static const CGFloat EXPLANATION_HEIGHT = 40.0;

    UIFont * titleFont = [UIFont boldSystemFontOfSize:18.0];
    UIFont * explanationFont = [UIFont systemFontOfSize:14.0];

    [[self titleColor] set];
    CGSize titleSize = [title sizeWithFont:titleFont];
    CGRect titleRect =
        CGRectMake(
            LEFT_MARGIN,
            TOP_MARGIN,
            self.bounds.size.width - (LEFT_MARGIN + RIGHT_MARGIN),
            titleSize.height);
    [title drawInRect:titleRect withFont:titleFont
        lineBreakMode:UILineBreakModeTailTruncation];

    [[self explanationColor] set];
    CGRect explanationRect =
        CGRectMake(
            LEFT_MARGIN,
            TOP_MARGIN + titleSize.height + ELEMENT_SPACE,
            self.bounds.size.width - (LEFT_MARGIN + RIGHT_MARGIN),
            EXPLANATION_HEIGHT);

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
