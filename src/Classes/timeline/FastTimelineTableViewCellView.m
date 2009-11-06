//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FastTimelineTableViewCellView.h"
#import "TwitbitShared.h"


static const CGFloat AVATAR_WIDTH = 48.0;
static const CGFloat AVATAR_HEIGHT = 48.0;
static const CGFloat AVATAR_ROUNDED_CORNER_RADIUS = 6.0;

static const CGFloat TEXT_WIDTH_WITH_AVATAR = 249.0;
static const CGFloat TEXT_WIDTH_WITHOUT_AVATAR = 304.0;

static const CGFloat TEXT_WIDTH_WITH_AVATAR_LANDSCAPE = 409;
static const CGFloat TEXT_WIDTH_WITHOUT_AVATAR_LANDSCAPE = 464;

static BOOL lightTheme;

static UIImage * normalTopImage;
static UIImage * normalBottomImage;
static UIImage * mentionTopImage;
static UIImage * mentionBottomImage;
static UIImage * darkenedTopImage;
static UIImage * darkenedBottomImage;

static UIFont * authorFont;
static UIFont * timestampFont;
static UIFont * textFont;
static UIFont * favoriteFont;


@interface FastTimelineTableViewCellView ()

- (void)drawRectNormal:(CGRect)rect;
- (void)drawRectInverted:(CGRect)rect;
- (void)drawRectNoAvatar:(CGRect)rect;
- (void)drawRectNormalNoName:(CGRect)rect;

- (void)drawBackground;
- (void)drawHighlightedAvatarBorderWithTopMargin:(NSInteger)topMargin
    leftMargin:(NSInteger)leftMargin;

- (UIColor *)authorColor;
- (UIColor *)timestampColor;
- (UIColor *)textColor;
- (UIColor *)favoriteColor;

+ (NSString *)starText;

@end

@implementation FastTimelineTableViewCellView

@synthesize landscape, highlighted;
@synthesize displayType, text, author, timestamp, avatar, favorite;
@synthesize displayAsMention, displayAsOld;

+ (void)initialize
{
    //
    // Background images
    //

    lightTheme = [SettingsReader displayTheme] == kDisplayThemeLight;

    normalTopImage =
        lightTheme ?
        [[UIImage imageNamed:@"TableViewCellTopGradient.png"] retain] :
        [[UIImage imageNamed:@"DarkThemeTopGradient.png"] retain];
    normalBottomImage =
        lightTheme ?
        [[UIImage imageNamed:@"TableViewCellGradient.png"] retain] :
        [[UIImage imageNamed:@"DarkThemeBottomGradient.png"] retain];
    mentionTopImage =
        lightTheme ?
        [[UIImage imageNamed:@"MentionTopGradient.png"] retain] :
        [[UIImage imageNamed:@"MentionTopGradientDarkTheme.png"] retain];
    mentionBottomImage =
        lightTheme ?
        [[UIImage imageNamed:@"MentionBottomGradient.png"] retain] :
        [[UIImage imageNamed:@"MentionBottomGradientDarkTheme.png"] retain];
    darkenedTopImage =
        lightTheme ?
        [[UIImage imageNamed:@"DarkenedTableViewCellTopGradient.png"] retain] :
        [[UIImage imageNamed:@"DarkenedDarkThemeTopGradient.png"] retain];
    darkenedBottomImage =
        lightTheme ?
        [[UIImage imageNamed:@"DarkenedTableViewCellGradient.png"] retain] :
        [[UIImage imageNamed:@"DarkenedDarkThemeBottomGradient.png"] retain];

    //
    // Fonts
    //
    authorFont = [[UIFont boldSystemFontOfSize:16.0] retain];
    timestampFont = [[UIFont systemFontOfSize:14.0] retain];
    textFont = [[UIFont systemFontOfSize:14.0] retain];
    favoriteFont = [[UIFont boldSystemFontOfSize:16.0] retain];
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
        self.backgroundColor = [UIColor defaultTimelineCellColor];

        landscape = NO;
        favorite = NO;
        displayType = FastTimelineTableViewCellDisplayTypeNormal;
        displayAsMention = NO;
        displayAsOld = NO;
    }

    return self;
}

- (void)drawRect:(CGRect)rect
{
    switch (displayType) {
        case FastTimelineTableViewCellDisplayTypeInverted:
            [self drawRectInverted:rect];
            break;
        case FastTimelineTableViewCellDisplayTypeNoAvatar:
            [self drawRectNoAvatar:rect];
            break;
        case FastTimelineTableViewCellDisplayTypeNormalNoName:
            [self drawRectNormalNoName:rect];
            break;
        case FastTimelineTableViewCellDisplayTypeNormal:
        default:
            [self drawRectNormal:rect];
            break;
    }
}

- (void)drawRectNormal:(CGRect)rect
{
    static const CGFloat TIMESTAMP_RIGHT_MARGIN = 9.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat AUTHOR_TOP_MARGIN = 5.0;
    static const CGFloat AUTHOR_LEFT_MARGIN = 62.0;

    static const CGFloat TEXT_LEFT_MARGIN = 62.0;
    static const CGFloat TEXT_TOP_MARGIN = 27.0;

    const CGFloat AVATAR_LEFT_MARGIN = 7.0;
    const CGFloat AVATAR_TOP_MARGIN = 7.0;

    if (highlighted)
        [self drawHighlightedAvatarBorderWithTopMargin:6 leftMargin:6];
    else
        [self drawBackground];

    CGRect contentRect = self.bounds;

    CGPoint point;
    CGSize size;

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

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
}

- (void)drawRectInverted:(CGRect)rect
{
    static const CGFloat TIMESTAMP_LEFT_MARGIN = 7.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat TEXT_LEFT_MARGIN = 7.0;
    static const CGFloat TEXT_TOP_MARGIN = 27.0;

    static const CGFloat AVATAR_RIGHT_MARGIN = 9.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    CGPoint point;
    CGSize size;

    if (highlighted) {
        CGFloat cellWidth = landscape ? 480 : 320;
        CGFloat leftMargin =
            cellWidth - (AVATAR_RIGHT_MARGIN + AVATAR_WIDTH + 1);
        [self drawHighlightedAvatarBorderWithTopMargin:6 leftMargin:leftMargin];
    } else
        [self drawBackground];

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

    [[self timestampColor] set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);

    [timestamp drawAtPoint:point withFont:timestampFont];

    //
    // Draw the favorite indicator
    //
    if (favorite) {
        [[self favoriteColor] set];
        point =
            CGPointMake(TEXT_LEFT_MARGIN + size.width + 5,
            TIMESTAMP_TOP_MARGIN - 2);
        size = CGSizeMake(13, favoriteFont.pointSize);

        [[[self class] starText] drawAtPoint:point forWidth:size.width
            withFont:favoriteFont fontSize:favoriteFont.pointSize
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
    point = CGPointMake(TEXT_LEFT_MARGIN, TEXT_TOP_MARGIN);

    CGRect drawingRect = CGRectMake(TEXT_LEFT_MARGIN, TEXT_TOP_MARGIN,
        size.width, size.height);

    [text drawInRect:drawingRect
            withFont:textFont
       lineBreakMode:UILineBreakModeWordWrap];

    //
    // Draw the avatar.
    //
    CGFloat avatarLeftMargin =
        self.bounds.size.width - AVATAR_WIDTH - AVATAR_RIGHT_MARGIN;
    CGRect avatarRect =
        CGRectMake(avatarLeftMargin, AVATAR_TOP_MARGIN, AVATAR_WIDTH,
        AVATAR_HEIGHT);
    [avatar drawInRect:avatarRect
        withRoundedCornersWithRadius:AVATAR_ROUNDED_CORNER_RADIUS];
}

- (void)drawRectNoAvatar:(CGRect)rect
{
    const CGFloat TIMESTAMP_LEFT_MARGIN = 9.0;
    const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    const CGFloat TEXT_LEFT_MARGIN = 7.0;
    static const CGFloat TEXT_TOP_MARGIN = 27.0;

    CGPoint point;
    CGSize size;

    if (!highlighted)
        [self drawBackground];

    //
    // Draw the timestamp.
    //

    [[self timestampColor] set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);
    [timestamp drawAtPoint:point withFont:timestampFont];

    //
    // Draw the favorite indicator
    //
    if (favorite) {
        [[self favoriteColor] set];
        point =
            CGPointMake(TEXT_LEFT_MARGIN + size.width + 5,
            TIMESTAMP_TOP_MARGIN - 2);
        size = CGSizeMake(13, favoriteFont.pointSize);

        [[[self class] starText] drawAtPoint:point forWidth:size.width
            withFont:favoriteFont fontSize:favoriteFont.pointSize
            lineBreakMode:UILineBreakModeTailTruncation
            baselineAdjustment:UIBaselineAdjustmentNone];
    }

    //
    // Draw the main text.
    //
    CGFloat textWidth =
        landscape ?
        TEXT_WIDTH_WITHOUT_AVATAR_LANDSCAPE : TEXT_WIDTH_WITHOUT_AVATAR;
    [[self textColor] set];
    CGSize textSize = CGSizeMake(textWidth, 999999.0);
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

- (void)drawRectNormalNoName:(CGRect)rect
{
    static const CGFloat TIMESTAMP_LEFT_MARGIN = 62.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat TEXT_LEFT_MARGIN = 62.0;
    static const CGFloat TEXT_TOP_MARGIN = 27.0;

    static const CGFloat AVATAR_LEFT_MARGIN = 7.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    CGPoint point;
    CGSize size;

    if (highlighted)
        [self drawHighlightedAvatarBorderWithTopMargin:6 leftMargin:6];
    else
        [self drawBackground];

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

    [[self timestampColor] set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);

    [timestamp drawAtPoint:point withFont:timestampFont];

    //
    // Draw the main text.
    //
    CGFloat textWidth =
        landscape ? TEXT_WIDTH_WITH_AVATAR_LANDSCAPE : TEXT_WIDTH_WITH_AVATAR;
    [[self textColor] set];
    CGSize textSize = CGSizeMake(textWidth, 99999.0);
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
    CGRect avatarRect =
        CGRectMake(AVATAR_LEFT_MARGIN, AVATAR_TOP_MARGIN, AVATAR_WIDTH,
        AVATAR_HEIGHT);
    [avatar drawInRect:avatarRect
        withRoundedCornersWithRadius:AVATAR_ROUNDED_CORNER_RADIUS];
}

#pragma mark Accessors

- (void)setLandscape:(BOOL)isLandscape
{
    if (landscape != isLandscape) {
        landscape = isLandscape;

        [self setNeedsDisplay];
    }
}

- (void)setDisplayType:(FastTimelineTableViewCellDisplayType)aType
{
    if (displayType != aType) {
        displayType = aType;

        [self setNeedsDisplay];
    }
}

- (void)setText:(NSString *)s
{
    if (text != s && ![text isEqualToString:s]) {
        [text release];
        text = [s copy];
    
        [self setNeedsDisplay];
    }
}

- (void)setAuthor:(NSString *)s
{
    if (author != s && ![author isEqualToString:s]) {
        [author release];
        author = [s copy];

        [self setNeedsDisplay];
    }
}

- (void)setTimestamp:(NSString *)s
{
    if (timestamp != s && ![timestamp isEqualToString:s]) {
        [timestamp release];
        timestamp = [s copy];

        [self setNeedsDisplay];
    }
}

- (void)setAvatar:(UIImage *)anAvatar
{
    if (avatar != anAvatar) {
        [avatar release];
        avatar = [anAvatar retain];

        [self setNeedsDisplay];
    }
}

- (void)setFavorite:(BOOL)isFavorite
{
    if (favorite != isFavorite) {
        favorite = isFavorite;
        [self setNeedsDisplay];
    }
}

- (void)setDisplayAsMention:(BOOL)shouldDisplayAsMention
{
    if (displayAsMention != shouldDisplayAsMention) {
        displayAsMention = shouldDisplayAsMention;
        self.backgroundColor =
            displayAsMention ?
            [UIColor mentionCellColor] : [UIColor whiteColor];

        [self setNeedsDisplay];
    }
}

- (void)setDisplayAsOld:(BOOL)shouldDisplayAsOld
{
    if (displayAsOld != shouldDisplayAsOld) {
        displayAsOld = shouldDisplayAsOld;
        UIColor * cellColor =
            displayAsOld ?
            [UIColor darkenedCellColor] :
            [UIColor defaultTimelineCellColor];
        self.backgroundColor = cellColor;

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

#pragma mark Public class implementation

+ (CGFloat)heightForContent:(NSString *)tweetText
                displayType:(FastTimelineTableViewCellDisplayType)displayType
                  landscape:(BOOL)landscape
{
    static const CGFloat MIN_CELL_HEIGHT = 63.0;

    CGFloat textWidth;
    if (displayType == FastTimelineTableViewCellDisplayTypeNoAvatar)
        textWidth =
            landscape ?
            TEXT_WIDTH_WITHOUT_AVATAR_LANDSCAPE : TEXT_WIDTH_WITHOUT_AVATAR;
    else
        textWidth =
            landscape ?
            TEXT_WIDTH_WITH_AVATAR_LANDSCAPE : TEXT_WIDTH_WITH_AVATAR;

    UILineBreakMode mode = UILineBreakModeWordWrap;
    CGSize maxSize = CGSizeMake(textWidth, 999999999.0);
    CGSize size = [tweetText sizeWithFont:textFont
                        constrainedToSize:maxSize
                            lineBreakMode:mode];

    NSInteger minHeight =
        displayType == FastTimelineTableViewCellDisplayTypeNoAvatar ?
        0 : MIN_CELL_HEIGHT;

    return MAX(35.0 + size.height, minHeight);
}

#pragma mark Private implementation

- (void)drawHighlightedAvatarBorderWithTopMargin:(NSInteger)topMargin
    leftMargin:(NSInteger)leftMargin
{
    CGFloat roundedCornerWidth = AVATAR_ROUNDED_CORNER_RADIUS * 2 + 1;
    CGFloat roundedCornerHeight = AVATAR_ROUNDED_CORNER_RADIUS * 2 + 1;

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);

    CGContextFillRect(context,
        CGRectMake(AVATAR_ROUNDED_CORNER_RADIUS + leftMargin, topMargin,
        AVATAR_WIDTH + 2 - roundedCornerWidth, AVATAR_HEIGHT + 2));

    // Draw rounded corners
    CGContextFillEllipseInRect(context,
        CGRectMake(leftMargin, topMargin, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillEllipseInRect(context,
        CGRectMake(leftMargin,
        AVATAR_HEIGHT + 2 + topMargin - roundedCornerHeight,
        roundedCornerWidth, roundedCornerHeight));
    CGContextFillRect(context,
        CGRectMake(leftMargin, topMargin + 1 + roundedCornerHeight / 2,
        roundedCornerWidth, AVATAR_HEIGHT  + 1 - roundedCornerHeight));

    CGContextFillEllipseInRect(context,
        CGRectMake(leftMargin + 2 + AVATAR_WIDTH - roundedCornerWidth,
        topMargin, roundedCornerWidth, roundedCornerHeight));
    CGContextFillEllipseInRect(context,
        CGRectMake(leftMargin + 2 + AVATAR_WIDTH - roundedCornerWidth,
        AVATAR_HEIGHT + 2 + topMargin - roundedCornerHeight, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillRect(context,
        CGRectMake(leftMargin + 2 + AVATAR_WIDTH - roundedCornerWidth,
        topMargin + 1 + roundedCornerHeight / 2, roundedCornerWidth,
        AVATAR_HEIGHT - roundedCornerHeight));
}


- (void)drawBackground
{
    UIImage * topImage;
    UIImage * bottomImage;

    if (displayAsMention) {
        topImage = mentionTopImage;
        bottomImage = mentionBottomImage;
    } else if (displayAsOld) {
        topImage = darkenedTopImage;
        bottomImage = darkenedBottomImage;
    } else {
        topImage = normalTopImage;
        bottomImage = normalBottomImage;
    }

    CGRect topImageRect = CGRectMake(0, 0, 480.0, topImage.size.height);
    [topImage drawInRect:topImageRect];

    CGRect bottomImageRect =
        CGRectMake(0,
        self.bounds.size.height - bottomImage.size.height,
        480.0, bottomImage.size.height);
    [bottomImage drawInRect:bottomImageRect];

    /*
    CGRect backgroundImageRect =
        CGRectMake(
        0,
        self.bounds.size.height - bottomImageRect.size.height + 1,
        480.0,
        bottomImageRect.size.height);
        */

    /*
    CGRect backgroundImageRect =
        CGRectMake(0,
        self.bounds.size.height - normalBottomImage.size.height + 1,
        480.0, normalBottomImage.size.height);
    [normalBottomImage drawInRect:backgroundImageRect];

    CGRect topGradientImageRect =
        CGRectMake(0, 0, 480.0, normalTopImage.size.height);
    [normalTopImage drawInRect:topGradientImageRect];
    */

    /*
    UIImage * bottomImage;
    UIImage * topImage;
    if (highlightForMention) {
        bottomImage = mentionBottomImage;
        topImage = mentionTopImage;
    } else if (darkenForOld) {
        bottomImage = darkenedBottomImage;
        topImage = darkenedTopImage;
    } else {
        bottomImage = backgroundImage;
        topImage = topGradientImage;
    }
    CGRect backgroundImageRect =
        CGRectMake(0, self.bounds.size.height - bottomImage.size.height,
        480.0, backgroundImage.size.height);
    [bottomImage drawInRect:backgroundImageRect];
    
    CGRect topGradientImageRect =
        CGRectMake(0, 0, 480.0, topImage.size.height);
    [topImage drawInRect:topGradientImageRect];
     */
}

- (UIColor *)authorColor
{
    if (highlighted)
        return [UIColor whiteColor];
    else
        return lightTheme ? [UIColor blackColor] : [UIColor whiteColor];
}

- (UIColor *)timestampColor
{
    if (highlighted)
        return [UIColor whiteColor];
    else
        return lightTheme ?
            [UIColor twitchBlueColor] :
            [UIColor twitchBlueOnDarkBackgroundColor];
}

- (UIColor *)textColor
{
    if (highlighted)
        return [UIColor whiteColor];
    else
        return lightTheme ?
            [UIColor blackColor] : [UIColor twitchLightLightGrayColor];
}

- (UIColor *)favoriteColor
{
    return highlighted ? [UIColor whiteColor] : [UIColor grayColor];
}

+ (NSString *)starText
{
    return @"★";
}

@end
