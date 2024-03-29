//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AccountCellView.h"
#import "UIImage+DrawingAdditions.h"
#import "UIColor+TwitchColors.h"

@interface AccountCellView ()

@property (nonatomic, readonly) UIImage * checkMark;
@property (nonatomic, readonly) UIImage * highlightedCheckMark;

@end

@implementation AccountCellView

@synthesize avatar, highlighted, landscape, selectedAccount;

- (void)dealloc
{
    [username release];
    [avatar release];
    [checkMark release];
    [highlightedCheckMark release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
		self.backgroundColor = [UIColor defaultDarkThemeCellColor];
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

- (void)setSelectedAccount:(BOOL)s
{
    if (selectedAccount != s) {
        selectedAccount = s;
        [self setNeedsDisplay];
    }
}

- (void)setUsername:(NSString *)aUsername
{
    NSString * usernameCopy = [aUsername copy];
    [username release];
    username = usernameCopy;

    [self setNeedsDisplay];
}

- (NSString *)username
{
    return username;
}

- (void)setAvatar:(UIImage *)anAvatar
{
    [anAvatar retain];
    [avatar release];
    avatar = anAvatar;

    [self setNeedsDisplay];
}

- (UIImage *)checkMark
{
    if (!checkMark)
        checkMark =
            [[UIImage imageNamed:@"AccountSelectedCheckmark.png"] retain];

    return checkMark;
}

- (UIImage *)highlightedCheckMark
{
    if (!highlightedCheckMark)
        highlightedCheckMark =
            [[UIImage imageNamed:@"AccountSelectedCheckmarkHighlighted.png"]
            retain];

    return highlightedCheckMark;
}

- (void)drawRect:(CGRect)rect
{
#define TOP_MARGIN 2
#define LEFT_MARGIN 5

#define ROUNDED_CORNER_RADIUS 4
#define AVATAR_WIDTH 28

    UIColor * usernameColor = nil;
    UIFont * usernameFont = [UIFont boldSystemFontOfSize:20.0];
    
    usernameColor = [UIColor whiteColor];
    
    [usernameColor set];
    CGPoint point = CGPointMake(48, 5);
    [username drawAtPoint:point withFont:usernameFont];
    
    //
    // Draw avatar
    //
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor * rectColor =
        highlighted ?
        [UIColor whiteColor] : [UIColor twitchLightLightGrayColor];

    CGContextSetFillColorWithColor(context, [rectColor CGColor]);
    
    CGFloat roundedCornerWidth = ROUNDED_CORNER_RADIUS * 2 + 1;
    CGFloat roundedCornerHeight = ROUNDED_CORNER_RADIUS * 2 + 1;
    
    CGContextFillRect(context,
        CGRectMake(ROUNDED_CORNER_RADIUS + LEFT_MARGIN, TOP_MARGIN,
        AVATAR_WIDTH + 2 - roundedCornerWidth, AVATAR_WIDTH + 2));
    
    // Draw rounded corners
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN, TOP_MARGIN, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN,
        AVATAR_WIDTH + 2 + TOP_MARGIN - roundedCornerHeight, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillRect(context,
        CGRectMake(LEFT_MARGIN, TOP_MARGIN + 1 + roundedCornerHeight / 2,
        roundedCornerWidth, AVATAR_WIDTH + 1 - roundedCornerHeight));
    
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN + 2 + AVATAR_WIDTH - roundedCornerWidth,
        TOP_MARGIN, roundedCornerWidth, roundedCornerHeight));
    CGContextFillEllipseInRect(context,
        CGRectMake(LEFT_MARGIN + 2 + AVATAR_WIDTH - roundedCornerWidth,
        AVATAR_WIDTH + 2 + TOP_MARGIN - roundedCornerHeight, roundedCornerWidth,
        roundedCornerHeight));
    CGContextFillRect(context,
        CGRectMake(LEFT_MARGIN + 2 + AVATAR_WIDTH - roundedCornerWidth,
        TOP_MARGIN + 1 + roundedCornerHeight / 2, roundedCornerWidth,
        AVATAR_WIDTH - roundedCornerHeight));
    
    CGRect avatarRect =
        CGRectMake(LEFT_MARGIN + 1, TOP_MARGIN + 1, AVATAR_WIDTH, AVATAR_WIDTH);
    [avatar drawInRect:avatarRect
        withRoundedCornersWithRadius:ROUNDED_CORNER_RADIUS];
}

@end
