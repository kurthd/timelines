//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TimelineTableViewCellView.h"
#import "UIColor+TwitchColors.h"
#import "UIImage+DrawingAdditions.h"

static UIImage * backgroundImage;

@interface TimelineTableViewCellView ()

- (void)drawRectNormal:(CGRect)rect;
- (void)drawRectInverted:(CGRect)rect;
- (void)drawRectNoAvatar:(CGRect)rect;
- (void)drawRectNoAuthor:(CGRect)rect;

- (void)setStringValue:(NSString **)dest to:(NSString *)source;
+ (CGFloat)degreesToRadians:(CGFloat)degrees;

@end

@implementation TimelineTableViewCellView

@synthesize text, author, timestamp, avatar, cellType;
@synthesize highlighted;

+ (void)initialize
{
    NSAssert(!backgroundImage, @"backgroundImage should be nil.");
    backgroundImage =
        [[UIImage imageNamed:@"TableViewCellGradient.png"] retain];
}

- (void)dealloc
{
    self.text = nil;
    self.author = nil;
    self.timestamp = nil;
    self.avatar = nil;

    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.opaque = YES;
        self.backgroundColor = [UIColor clearColor];
    }

    return self;
}

#pragma mark Drawing the view

- (void)drawRect:(CGRect)rect
{
    //
    // Per the documentation, direct UIView subclasses do not need to call
    // super's implementation.
    //

    switch (cellType) {
        case kTimelineTableViewCellTypeNormal:
            [self drawRectNormal:rect];
            break;
        case kTimelineTableViewCellTypeInverted:
            [self drawRectInverted:rect];
            break;
        case kTimelineTableViewCellTypeNoAvatar:
            [self drawRectNoAvatar:rect];
            break;
        case kTimelineTableViewCellTypeNormalNoName:
            [self drawRectNoAuthor:rect];
            break;
    }
}

- (void)drawRectNormal:(CGRect)rect
{
    static const CGFloat TIMESTAMP_RIGHT_MARGIN = 0.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat AUTHOR_TOP_MARGIN = 5.0;
    static const CGFloat AUTHOR_LEFT_MARGIN = 64.0;

    static const CGFloat TEXT_LEFT_MARGIN = 64.0;
    static const CGFloat TEXT_RIGHT_MARGIN = 0.0;
    static const CGFloat TEXT_TOP_MARGIN = 28.0;

    static const CGFloat AVATAR_LEFT_MARGIN = 7.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    UIColor * authorColor = nil;
    UIFont * authorFont = [UIFont boldSystemFontOfSize:16.0];

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    CGRect contentRect = self.bounds;

    CGPoint point;
    CGSize size;

    if (highlighted) {
        authorColor = [UIColor whiteColor];
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
    } else {
        authorColor = [UIColor blackColor];
        timestampColor = [UIColor twitchBlueColor];
        textColor = [UIColor blackColor];

        //
        // Draw the cell's background.
        //
        CGRect backgroundImageRect =
            CGRectMake(0,
            contentRect.size.height - backgroundImage.size.height,
            320.0, backgroundImage.size.height);
        [backgroundImage drawInRect:backgroundImageRect];
    }

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

    [timestampColor set];
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

    [authorColor set];
    size = CGSizeMake(point.x - 5.0 - AUTHOR_LEFT_MARGIN, authorFont.pointSize);
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

    //
    // Draw the avatar.
    //

    point = CGPointMake(AVATAR_LEFT_MARGIN, AVATAR_TOP_MARGIN);
    [avatar drawWithRoundedCornersAtPoint:point withRadius:6.0];
}

- (void)drawRectInverted:(CGRect)rect
{
    static const CGFloat TIMESTAMP_LEFT_MARGIN = 7.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat TEXT_LEFT_MARGIN = 7.0;
    static const CGFloat TEXT_RIGHT_MARGIN = 64.0;
    static const CGFloat TEXT_TOP_MARGIN = 28.0;

    static const CGFloat AVATAR_LEFT_MARGIN = 245.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    CGRect contentRect = self.bounds;

    CGPoint point;
    CGSize size;

    if (highlighted) {
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
    } else {
        timestampColor = [UIColor twitchBlueColor];
        textColor = [UIColor blackColor];

        //
        // Draw the cell's background.
        //
        CGRect backgroundImageRect =
            CGRectMake(0,
            contentRect.size.height - backgroundImage.size.height,
            320.0, backgroundImage.size.height);
        [backgroundImage drawInRect:backgroundImageRect];
    }

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

    [timestampColor set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);

    [timestamp drawAtPoint:point withFont:timestampFont];

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

    //
    // Draw the avatar.
    //

    point = CGPointMake(AVATAR_LEFT_MARGIN, AVATAR_TOP_MARGIN);
    [avatar drawWithRoundedCornersAtPoint:point withRadius:6.0];
}

- (void)drawRectNoAvatar:(CGRect)rect
{
    static const CGFloat TIMESTAMP_LEFT_MARGIN = 7.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat TEXT_LEFT_MARGIN = 7.0;
    static const CGFloat TEXT_RIGHT_MARGIN = 0.0;
    static const CGFloat TEXT_TOP_MARGIN = 28.0;

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    CGRect contentRect = self.bounds;

    CGPoint point;
    CGSize size;

    if (highlighted) {
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
    } else {
        timestampColor = [UIColor twitchBlueColor];
        textColor = [UIColor blackColor];

        //
        // Draw the cell's background.
        //
        CGRect backgroundImageRect =
            CGRectMake(0,
            contentRect.size.height - backgroundImage.size.height,
            320.0, backgroundImage.size.height);
        [backgroundImage drawInRect:backgroundImageRect];
    }

    //
    // Draw the timestamp.
    //

    [timestampColor set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);
    [timestamp drawAtPoint:point withFont:timestampFont];

    //
    // Draw the main text.
    //

    [textColor set];
    CGSize textSize =
        CGSizeMake(
        contentRect.size.width - TEXT_LEFT_MARGIN - TEXT_RIGHT_MARGIN,
        99999.0);
    size = [text sizeWithFont:textFont
            constrainedToSize:textSize
                lineBreakMode:UILineBreakModeWordWrap];
    point = CGPointMake(TEXT_LEFT_MARGIN, TEXT_TOP_MARGIN);

    CGRect drawingRect = CGRectMake(TEXT_LEFT_MARGIN, TEXT_TOP_MARGIN,
        size.width, size.height);

    [text drawInRect:drawingRect
            withFont:textFont
       lineBreakMode:UILineBreakModeWordWrap];
}

- (void)drawRectNoAuthor:(CGRect)rect
{
    static const CGFloat TIMESTAMP_LEFT_MARGIN = 64.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat TEXT_LEFT_MARGIN = 64.0;
    static const CGFloat TEXT_RIGHT_MARGIN = 0.0;
    static const CGFloat TEXT_TOP_MARGIN = 28.0;

    static const CGFloat AVATAR_LEFT_MARGIN = 7.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    CGRect contentRect = self.bounds;

    CGPoint point;
    CGSize size;

    if (highlighted) {
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
    } else {
        timestampColor = [UIColor twitchBlueColor];
        textColor = [UIColor blackColor];

        //
        // Draw the cell's background.
        //
        CGRect backgroundImageRect =
            CGRectMake(0,
            contentRect.size.height - backgroundImage.size.height,
            320.0, backgroundImage.size.height);
        [backgroundImage drawInRect:backgroundImageRect];
    }

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

    [timestampColor set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);

    [timestamp drawAtPoint:point withFont:timestampFont];

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

    //
    // Draw the avatar.
    //

    point = CGPointMake(AVATAR_LEFT_MARGIN, AVATAR_TOP_MARGIN);
    [avatar drawWithRoundedCornersAtPoint:point withRadius:6.0];
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

- (void)setCellType:(TimelineTableViewCellType)type
{
    if (cellType != type) {
        cellType = type;
        [self setNeedsDisplay];
    }
}

#pragma mark Private helpers

- (void)setStringValue:(NSString **)dest to:(NSString *)source
{
    if (*dest != source && ![*dest isEqualToString:source]) {
        [*dest release];
        *dest = [source copy];

        [self setNeedsDisplay];
    }
}

+ (CGFloat)degreesToRadians:(CGFloat)degrees
{
    return degrees / 57.2958;
}

@end
