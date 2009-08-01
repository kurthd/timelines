//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TimelineTableViewCellView.h"
#import "UIColor+TwitchColors.h"

@interface TimelineTableViewCellView ()

- (void)setStringValue:(NSString **)dest to:(NSString *)source;

@end

@implementation TimelineTableViewCellView

@synthesize text, author, timestamp, avatar;
@synthesize highlighted;

- (void)dealloc
{
    self.text = nil;
    self.author = nil;
    self.timestamp = nil;
    self.avatar = nil;
    
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];
    }

    return self;
}

#pragma mark Drawing the view

static const CGFloat TIMESTAMP_RIGHT_MARGIN = 0.0;
static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

static const CGFloat AUTHOR_TOP_MARGIN = 5.0;
static const CGFloat AUTHOR_LEFT_MARGIN = 64.0;

static const CGFloat TEXT_LEFT_MARGIN = 64.0;
static const CGFloat TEXT_RIGHT_MARGIN = 0.0;
static const CGFloat TEXT_TOP_MARGIN = 28.0;

- (void)drawRect:(CGRect)rect
{
    //
    // Per the documentation, direct UIView subclasses do not need to call
    // super's implementation.
    //

    UIColor * authorColor = nil;
    UIFont * authorFont = [UIFont boldSystemFontOfSize:16.0];

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    if (highlighted) {
        authorColor = [UIColor whiteColor];
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
    } else {
        authorColor = [UIColor blackColor];
        timestampColor = [UIColor twitchBlueColor];
        textColor = [UIColor blackColor];
    }

    CGRect contentRect = self.bounds;
    CGFloat boundsX = contentRect.origin.x;

    CGPoint point;
    CGSize size;

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

    [timestampColor set];
    size = [timestamp sizeWithFont:timestampFont];
    point =
        CGPointMake(
            (boundsX + contentRect.size.width) -
            TIMESTAMP_RIGHT_MARGIN - size.width,
            TIMESTAMP_TOP_MARGIN);

    [timestamp drawAtPoint:point withFont:timestampFont];

    //
    // Draw the author in the space that remains between the avatar and the
    // timestamp, without shrinking the text
    //

    [authorColor set];
    CGSize authorSize =
        CGSizeMake((AUTHOR_LEFT_MARGIN + point.x) - 5.0,
        99999.0);  // can this be authorFont.pointSize?
    size = [author sizeWithFont:authorFont constrainedToSize:authorSize];
    point = CGPointMake(AUTHOR_LEFT_MARGIN, AUTHOR_TOP_MARGIN);

    [author drawAtPoint:point forWidth:size.width withFont:authorFont
        fontSize:authorFont.pointSize
        lineBreakMode:UILineBreakModeTailTruncation
        baselineAdjustment:UIBaselineAdjustmentNone];

    //
    // Draw the main text.
    //

    [textColor set];
    CGSize textSize =
        CGSizeMake(
        contentRect.size.width - TEXT_LEFT_MARGIN - TEXT_RIGHT_MARGIN, 99999.0);
    size = [text sizeWithFont:textFont
            constrainedToSize:textSize
                lineBreakMode:UILineBreakModeWordWrap];
    point = CGPointMake(TEXT_LEFT_MARGIN, TEXT_TOP_MARGIN);

    CGRect drawingRect = CGRectMake(TEXT_LEFT_MARGIN, TEXT_TOP_MARGIN,
        size.width, size.height);

    [text drawInRect:drawingRect
            withFont:textFont
       lineBreakMode:UILineBreakModeWordWrap];

    /*
    [text drawAtPoint:point
             forWidth:size.width
             withFont:textFont
        lineBreakMode:UILineBreakModeWordWrap];
     */
}

#pragma mark Accessors

- (void)setText:(NSString *)s
{
    [self setStringValue:&text to:s];
}

- (void)setAuthor:(NSString *)s
{
    [self setStringValue:&author to:s];
}

- (void)setTimestamp:(NSString *)s
{
    [self setStringValue:&timestamp to:s];
}

- (void)setAvatar:(UIImage *)image
{
    if (avatar != image) {
        [avatar release];
        avatar = [image retain];

        [self setNeedsDisplay];
    }
}

- (void)setHighlighted:(BOOL)b
{
    if (highlighted != b) {
        highlighted = b;
        [self setNeedsDisplay];
    }
}

- (void)setStringValue:(NSString **)dest to:(NSString *)source
{
    if (*dest != source && ![*dest isEqualToString:source]) {
        [*dest release];
        *dest = [source copy];

        [self setNeedsDisplay];
    }
}

@end
