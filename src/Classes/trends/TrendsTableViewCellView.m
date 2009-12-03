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
    CGSize explanationSize =
        CGSizeMake(self.bounds.size.width - LEFT_MARGIN * 2, 40);

    CGRect explanationRect =
        CGRectMake(
            point.x,
            point.y,
            explanationSize.width,
            explanationSize.height);

    [explanation drawInRect:explanationRect
                   withFont:explanationFont
              lineBreakMode:UILineBreakModeTailTruncation];


    /*
    [[self timestampColor] set];
    size = [timestamp sizeWithFont:timestampFont];
    point =
        CGPointMake(
            (contentRect.origin.x + contentRect.size.width) -
            TIMESTAMP_RIGHT_MARGIN - size.width,
            TIMESTAMP_TOP_MARGIN);

    [timestamp drawAtPoint:point withFont:timestampFont];

    //
    // Draw the author in the space that remains between the avatar and the
    // timestamp, without shrinking the text
    //

    [[self authorColor] set];
    CGFloat padding = favorite ? 19.0 : 5.0;
    size =
        CGSizeMake(point.x - padding - AUTHOR_LEFT_MARGIN,
        authorFont.pointSize);
    point = CGPointMake(AUTHOR_LEFT_MARGIN, AUTHOR_TOP_MARGIN);

    [author drawAtPoint:point forWidth:size.width withFont:authorFont
        fontSize:authorFont.pointSize
        lineBreakMode:UILineBreakModeTailTruncation
        baselineAdjustment:UIBaselineAdjustmentNone];

    //
    // Draw the favorite indicator
    //
    if (favorite) {
        [[self favoriteColor] set];
        point =
            CGPointMake(AUTHOR_LEFT_MARGIN + size.width + 2, AUTHOR_TOP_MARGIN);
        size = CGSizeMake(13, authorFont.pointSize);

        [[[self class] starText] drawAtPoint:point forWidth:size.width
            withFont:authorFont fontSize:authorFont.pointSize
            lineBreakMode:UILineBreakModeTailTruncation
            baselineAdjustment:UIBaselineAdjustmentNone];
    }
 
    //
    // Draw the main text.
    //
    [[self textColor] set];
    CGFloat textWidth =
        landscape ? TEXT_WIDTH_WITH_AVATAR_LANDSCAPE : TEXT_WIDTH_WITH_AVATAR;
    CGSize textSize = CGSizeMake(textWidth, 999999.0);
    size = [text sizeWithFont:textFont
            constrainedToSize:textSize
                lineBreakMode:UILineBreakModeWordWrap];

    CGRect drawingRect = CGRectMake(TEXT_LEFT_MARGIN, TEXT_TOP_MARGIN,
        size.width, size.height);

    [text drawInRect:drawingRect
            withFont:textFont
       lineBreakMode:UILineBreakModeWordWrap];

    //
    // Draw the avatar.
    //
    CGRect avatarRect =
        CGRectMake(AVATAR_LEFT_MARGIN, AVATAR_TOP_MARGIN, AVATAR_WIDTH,
        AVATAR_HEIGHT);
    [avatar drawInRect:avatarRect
        withRoundedCornersWithRadius:AVATAR_ROUNDED_CORNER_RADIUS];
    */
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
