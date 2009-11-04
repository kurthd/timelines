//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TimelineTableViewCellView.h"
#import "UIColor+TwitchColors.h"
#import "UIImage+DrawingAdditions.h"
#import "SettingsReader.h"

static const CGFloat TEXT_WIDTH_WITHOUT_AVATAR = 304.0;
static const CGFloat TEXT_WIDTH_WITHOUT_AVATAR_LANDSCAPE = 464.0;
static const CGFloat TEXT_WIDTH_WITH_AVATAR = 249.0;
static const CGFloat TEXT_WIDTH_WITH_AVATAR_LANDSCAPE = 409.0;

static const CGFloat AVATAR_WIDTH = 48.0;
static const CGFloat AVATAR_HEIGHT = 48.0;
static const CGFloat AVATAR_ROUNDED_CORNER_RADIUS = 6.0;

static UIImage * backgroundImage;
static UIImage * topGradientImage;
static UIImage * mentionBottomImage;
static UIImage * mentionTopImage;
static UIImage * darkenedBottomImage;
static UIImage * darkenedTopImage;

@interface TimelineTableViewCellView ()

- (void)drawRectNormal:(CGRect)rect;
- (void)drawRectInverted:(CGRect)rect;
- (void)drawRectNoAvatar:(CGRect)rect;
- (void)drawRectNoAuthor:(CGRect)rect;

- (void)drawHighlightedAvatarBorderWithTopMargin:(NSInteger)topMargin
    leftMargin:(NSInteger)leftMargin;

- (void)setStringValue:(NSString **)dest to:(NSString *)source;
+ (CGFloat)degreesToRadians:(CGFloat)degrees;

+ (NSString *)starText;

@end

@implementation TimelineTableViewCellView

static NSString * starText;

@synthesize text, author, timestamp, avatar, cellType, highlightForMention,
    darkenForOld, favorite;
@synthesize highlighted;
@synthesize landscape;

+ (void)initialize
{
    NSAssert(!backgroundImage, @"backgroundImage should be nil.");
    backgroundImage =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [[UIImage imageNamed:@"DarkThemeBottomGradient.png"] retain] :
        [[UIImage imageNamed:@"TableViewCellGradient.png"] retain];
    topGradientImage =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [[UIImage imageNamed:@"DarkThemeTopGradient.png"] retain] :
        [[UIImage imageNamed:@"TableViewCellTopGradient.png"] retain];
    mentionBottomImage =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [[UIImage imageNamed:@"MentionBottomGradientDarkTheme.png"] retain] :
        [[UIImage imageNamed:@"MentionBottomGradient.png"] retain];
    mentionTopImage =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [[UIImage imageNamed:@"MentionTopGradientDarkTheme.png"] retain] :
        [[UIImage imageNamed:@"MentionTopGradient.png"] retain];
    darkenedBottomImage =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [[UIImage imageNamed:@"DarkenedDarkThemeBottomGradient.png"] retain] :
        [[UIImage imageNamed:@"DarkenedTableViewCellGradient.png"] retain];
    darkenedTopImage =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [[UIImage imageNamed:@"DarkenedDarkThemeTopGradient.png"] retain] :
        [[UIImage imageNamed:@"DarkenedTableViewCellTopGradient.png"] retain];
}

+ (CGFloat)heightForContent:(NSString *)tweetText
                   cellType:(TimelineTableViewCellType)cellType
                  landscape:(BOOL)landscape
{
    CGFloat textWidthWithoutAvatar =
        !landscape ?
        TEXT_WIDTH_WITHOUT_AVATAR : TEXT_WIDTH_WITHOUT_AVATAR_LANDSCAPE;
    CGFloat textWidthWithAvatar =
        !landscape ? TEXT_WIDTH_WITH_AVATAR : TEXT_WIDTH_WITH_AVATAR_LANDSCAPE;
    CGFloat tweetTextLabelWidth =
        cellType == kTimelineTableViewCellTypeNoAvatar ?
        textWidthWithoutAvatar : textWidthWithAvatar;
    CGSize maxSize = CGSizeMake(tweetTextLabelWidth, 999999.0);

    UIFont * font = [UIFont systemFontOfSize:14.0];
    UILineBreakMode mode = UILineBreakModeWordWrap;

    CGSize size =
        [tweetText sizeWithFont:font constrainedToSize:maxSize
        lineBreakMode:mode];

    NSInteger minHeight =
        cellType == kTimelineTableViewCellTypeNoAvatar ?
        0 : 63;
    NSUInteger height = 35.0 + size.height;
    height = height > minHeight ? height : minHeight;

    return height;
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

        self.backgroundColor =
            highlightForMention ?
            [UIColor darkCellBackgroundColor] :
            [[self class] defaultTimelineCellColor];
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
    static const CGFloat TIMESTAMP_RIGHT_MARGIN = 9.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat AUTHOR_TOP_MARGIN = 5.0;
    static const CGFloat AUTHOR_LEFT_MARGIN = 62.0;

    static const CGFloat TEXT_LEFT_MARGIN = 62.0;
    static const CGFloat TEXT_TOP_MARGIN = 27.0;

    static const CGFloat AVATAR_LEFT_MARGIN = 7.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    UIColor * authorColor = nil;
    UIFont * authorFont = [UIFont boldSystemFontOfSize:16.0];

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    UIColor * favoriteColor = nil;

    CGRect contentRect = self.bounds;

    CGPoint point;
    CGSize size;

    if (highlighted) {
        authorColor = [UIColor whiteColor];
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
        favoriteColor = [UIColor whiteColor];
        [self drawHighlightedAvatarBorderWithTopMargin:6 leftMargin:6];
    } else {
        textColor =
                [SettingsReader displayTheme] == kDisplayThemeDark ?
                [UIColor twitchLightLightGrayColor] : [UIColor blackColor];
        authorColor =
               [SettingsReader displayTheme] == kDisplayThemeDark ?
               [UIColor whiteColor] : [UIColor blackColor];
        timestampColor = [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor twitchBlueOnDarkBackgroundColor] :
            [UIColor twitchBlueColor];
        favoriteColor = [UIColor grayColor];

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
    CGFloat padding = favorite ? 19.0 : 5.0;
    size =
        CGSizeMake(point.x - padding - AUTHOR_LEFT_MARGIN,
        authorFont.pointSize);
    point = CGPointMake(AUTHOR_LEFT_MARGIN, AUTHOR_TOP_MARGIN);

    [author drawAtPoint:point forWidth:size.width withFont:authorFont
        fontSize:authorFont.pointSize
        lineBreakMode:UILineBreakModeTailTruncation
        baselineAdjustment:UIBaselineAdjustmentNone];
    
    CGFloat authorWidth = size.width;
    
    if (favorite) {
        [favoriteColor set];
        size = CGSizeMake(13, authorFont.pointSize);
        point =
            CGPointMake(AUTHOR_LEFT_MARGIN + authorWidth + 2,
            AUTHOR_TOP_MARGIN);

        [[[self class] starText] drawAtPoint:point forWidth:size.width
            withFont:authorFont fontSize:authorFont.pointSize
            lineBreakMode:UILineBreakModeTailTruncation
            baselineAdjustment:UIBaselineAdjustmentNone];
    }

    //
    // Draw the main text.
    //
    [textColor set];
    CGFloat textWidth =
        !landscape ? TEXT_WIDTH_WITH_AVATAR : TEXT_WIDTH_WITH_AVATAR_LANDSCAPE;
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

    static const CGFloat AVATAR_LEFT_MARGIN = 261.0;
    static const CGFloat AVATAR_LEFT_MARGIN_LANDSCAPE = 421.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];
    
    UIColor * favoriteColor = nil;

    CGPoint point;
    CGSize size;

    CGFloat avatarLeftMargin =
        !landscape ? AVATAR_LEFT_MARGIN : AVATAR_LEFT_MARGIN_LANDSCAPE;

    if (highlighted) {
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
        favoriteColor = [UIColor whiteColor];
        [self drawHighlightedAvatarBorderWithTopMargin:6
            leftMargin:avatarLeftMargin - 1];
    } else {
        textColor =
                [SettingsReader displayTheme] == kDisplayThemeDark ?
                [UIColor twitchLightLightGrayColor] : [UIColor blackColor];
        timestampColor = [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor twitchBlueOnDarkBackgroundColor] :
            [UIColor twitchBlueColor];
        favoriteColor = [UIColor grayColor];

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
    }

    //
    // Draw the timestamp first since we'll draw the author within the
    // space that remains after the timestamp has been drawn.
    //

    [timestampColor set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);

    [timestamp drawAtPoint:point withFont:timestampFont];

    CGFloat timestampWidth = size.width;

    if (favorite) {
        [favoriteColor set];
        UIFont * favoriteFont = [UIFont boldSystemFontOfSize:16.0];
        size = CGSizeMake(13, favoriteFont.pointSize);
        point =
            CGPointMake(TEXT_LEFT_MARGIN + timestampWidth + 5,
            TIMESTAMP_TOP_MARGIN - 2);

        [[[self class] starText] drawAtPoint:point forWidth:size.width
            withFont:favoriteFont fontSize:favoriteFont.pointSize
            lineBreakMode:UILineBreakModeTailTruncation
            baselineAdjustment:UIBaselineAdjustmentNone];
    }

    //
    // Draw the main text.
    //
    [textColor set];
    CGFloat textWidth =
        !landscape ? TEXT_WIDTH_WITH_AVATAR : TEXT_WIDTH_WITH_AVATAR_LANDSCAPE;
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
    CGRect avatarRect =
        CGRectMake(avatarLeftMargin, AVATAR_TOP_MARGIN, AVATAR_WIDTH,
        AVATAR_HEIGHT);
    [avatar drawInRect:avatarRect
        withRoundedCornersWithRadius:AVATAR_ROUNDED_CORNER_RADIUS];
}

- (void)drawRectNoAvatar:(CGRect)rect
{
    static const CGFloat TIMESTAMP_LEFT_MARGIN = 7.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat TEXT_LEFT_MARGIN = 7.0;
    static const CGFloat TEXT_TOP_MARGIN = 27.0;

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    UIColor * favoriteColor = nil;

    CGPoint point;
    CGSize size;

    if (highlighted) {
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
        favoriteColor = [UIColor whiteColor];
    } else {
        textColor =
                [SettingsReader displayTheme] == kDisplayThemeDark ?
                [UIColor twitchLightLightGrayColor] : [UIColor blackColor];
        timestampColor = [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor twitchBlueOnDarkBackgroundColor] :
            [UIColor twitchBlueColor];
        favoriteColor = [UIColor grayColor];

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
    }

    //
    // Draw the timestamp.
    //

    [timestampColor set];
    size = [timestamp sizeWithFont:timestampFont];
    point = CGPointMake(TIMESTAMP_LEFT_MARGIN, TIMESTAMP_TOP_MARGIN);
    [timestamp drawAtPoint:point withFont:timestampFont];

    CGFloat timestampWidth = size.width;

    if (favorite) {
        [favoriteColor set];
        UIFont * favoriteFont = [UIFont boldSystemFontOfSize:16.0];
        size = CGSizeMake(13, favoriteFont.pointSize);
        point =
            CGPointMake(TEXT_LEFT_MARGIN + timestampWidth + 5,
            TIMESTAMP_TOP_MARGIN - 2);

        [[[self class] starText] drawAtPoint:point forWidth:size.width
            withFont:favoriteFont fontSize:favoriteFont.pointSize
            lineBreakMode:UILineBreakModeTailTruncation
            baselineAdjustment:UIBaselineAdjustmentNone];
    }

    //
    // Draw the main text.
    //
    CGFloat textWidth =
        !landscape ?
        TEXT_WIDTH_WITHOUT_AVATAR : TEXT_WIDTH_WITHOUT_AVATAR_LANDSCAPE;
    [textColor set];
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

- (void)drawRectNoAuthor:(CGRect)rect
{
    static const CGFloat TIMESTAMP_LEFT_MARGIN = 62.0;
    static const CGFloat TIMESTAMP_TOP_MARGIN = 7.0;

    static const CGFloat TEXT_LEFT_MARGIN = 62.0;
    static const CGFloat TEXT_TOP_MARGIN = 27.0;

    static const CGFloat AVATAR_LEFT_MARGIN = 7.0;
    static const CGFloat AVATAR_TOP_MARGIN = 7.0;

    UIColor * timestampColor = nil;
    UIFont * timestampFont = [UIFont systemFontOfSize:14.0];

    UIColor * textColor = nil;
    UIFont * textFont = [UIFont systemFontOfSize:14.0];

    CGPoint point;
    CGSize size;

    if (highlighted) {
        timestampColor = [UIColor whiteColor];
        textColor = [UIColor whiteColor];
        [self drawHighlightedAvatarBorderWithTopMargin:6 leftMargin:6];
    } else {
        textColor =
                [SettingsReader displayTheme] == kDisplayThemeDark ?
                [UIColor twitchLightLightGrayColor] : [UIColor blackColor];
        timestampColor = [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor twitchBlueOnDarkBackgroundColor] :
            [UIColor twitchBlueColor];

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
    CGFloat textWidth =
        !landscape ? TEXT_WIDTH_WITH_AVATAR : TEXT_WIDTH_WITH_AVATAR_LANDSCAPE;
    [textColor set];
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

- (void)setLandscape:(BOOL)l
{
    if (landscape != l) {
        landscape = l;
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

- (void)setHighlightForMention:(BOOL)hfm
{
    if (highlightForMention != hfm) {
        highlightForMention = hfm;
        UIColor * nonMentionCellColor =
            darkenForOld ?
            [TimelineTableViewCellView darkenedCellColor] :
            [TimelineTableViewCellView defaultTimelineCellColor];
        UIColor * cellColor =
            highlightForMention ?
            [TimelineTableViewCellView mentionCellColor] :
            nonMentionCellColor;
        self.backgroundColor = cellColor;
        // HACK: cell color doesn't always seem to update if this isn't delayed
        [self performSelector:@selector(setBackgroundColor:)
            withObject:cellColor afterDelay:0];
    }
}

- (void)setFavorite:(BOOL)fav
{
    if (favorite != fav) {
        favorite = fav;
        [self setNeedsDisplay];
    }
}

- (void)setDarkenForOld:(BOOL)darken
{
    if (darkenForOld != darken) {
        darkenForOld = darken;
        UIColor * cellColor =
            darken ?
            [TimelineTableViewCellView darkenedCellColor] :
            [TimelineTableViewCellView defaultTimelineCellColor];
        self.backgroundColor = cellColor;
        // HACK: cell color doesn't always seem to update if this isn't delayed
        [self performSelector:@selector(setBackgroundColor:)
            withObject:cellColor afterDelay:0];
    }
}
    
- (void)drawHighlightedAvatarBorderWithTopMargin:(NSInteger)topMargin
    leftMargin:(NSInteger)leftMargin
{
#define ROUNDED_CORNER_RADIUS 6

    CGFloat roundedCornerWidth = ROUNDED_CORNER_RADIUS * 2 + 1;
    CGFloat roundedCornerHeight = ROUNDED_CORNER_RADIUS * 2 + 1;

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);

    CGContextFillRect(context,
        CGRectMake(ROUNDED_CORNER_RADIUS + leftMargin, topMargin,
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

static UIColor * mentionCellColor;
+ (UIColor *)mentionCellColor
{
    if (!mentionCellColor)
        mentionCellColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [[UIColor twitchDarkGrayColor] retain] :
            [[UIColor colorWithRed:0.89 green:0.99 blue:0.89 alpha:1.0] retain];

    return mentionCellColor;
}

+ (UIColor *)defaultTimelineCellColor
{
    return [SettingsReader displayTheme] == kDisplayThemeDark ?
        [[self class] defaultDarkThemeCellColor] : [UIColor whiteColor];
}

static UIColor * defaultDarkThemeCellColor;
+ (UIColor *)defaultDarkThemeCellColor
{
    if (!defaultDarkThemeCellColor)
        defaultDarkThemeCellColor =
            [[UIColor colorWithRed:0.22 green:0.23 blue:0.24 alpha:1.0]
            retain];

    return defaultDarkThemeCellColor;
}

+ (UIColor *)darkenedCellColor
{
    return [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor colorWithRed:0.17 green:0.17 blue:0.17 alpha:1.0] :
        [UIColor darkCellBackgroundColor];
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

+ (NSString *)starText
{
    if (!starText)
        starText = @"★";

    return starText;
}

@end
