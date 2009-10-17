//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserSummaryView.h"
#import "User+UIAdditions.h"
#import "UIImage+DrawingAdditions.h"
#import "SettingsReader.h"
#import "UIColor+TwitchColors.h"

@interface UserSummaryView ()

+ (NSString *)usernameFormatString;
+ (UIColor *)lighterTextColor;
+ (UIColor *)darkerTextColor;
+ (UIImage *)avatarBackgroundImage;

@end

@implementation UserSummaryView

static NSString * usernameFormatString;
static UIColor * lighterTextColor;
static UIColor * darkerTextColor;
static UIImage * avatarBackgroundImage;

@synthesize avatar, highlighted, landscape;

- (void)dealloc
{
    [user release];
    [avatar release];
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

- (void)setLandscape:(BOOL)l
{
    if (landscape != l) {
        landscape = l;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
#define LEFT_MARGIN 73
#define TOP_MARGIN 6
#define LABEL_WIDTH 220
#define LABEL_WIDTH_LANDSCAPE 380

#define NAME_LABEL_FONT_SIZE 18

#define USERNAME_LABEL_FONT_SIZE 14
#define USERNAME_TOP_MARGIN 27

#define FOLLOWERS_LABEL_FONT_SIZE 14
#define FOLLOWERS_TOP_MARGIN 45

#define AVATAR_BACKGROUND_TOP_MARGIN 4
#define AVATAR_BACKGROUND_LEFT_MARGIN 4

#define AVATAR_LEFT_MARGIN 7
#define AVATAR_TOP_MARGIN 7
#define AVATAR_WIDTH 58
#define AVATAR_HEIGHT 58

    UIColor * nameLabelTextColor = nil;
    UIFont * nameLabelFont = [UIFont boldSystemFontOfSize:NAME_LABEL_FONT_SIZE];

	UIColor * usernameLabelTextColor = nil;
	UIFont * usernameLabelFont =
	    [UIFont systemFontOfSize:USERNAME_LABEL_FONT_SIZE];

	UIColor * followersLabelTextColor = nil;
	UIFont * followersLabelFont =
	    [UIFont systemFontOfSize:FOLLOWERS_LABEL_FONT_SIZE];

    if (self.highlighted) {
		nameLabelTextColor = [UIColor whiteColor];
		usernameLabelTextColor = [UIColor whiteColor];
		followersLabelTextColor = [UIColor whiteColor];
	} else {
        nameLabelTextColor = [[self class] darkerTextColor];
		usernameLabelTextColor = [[self class] lighterTextColor];
		followersLabelTextColor = [[self class] lighterTextColor];
	}

	CGRect contentRect = self.bounds;
	CGFloat boundsX = contentRect.origin.x;
	CGPoint point;
    CGFloat labelWidth = landscape ? LABEL_WIDTH_LANDSCAPE : LABEL_WIDTH;

    NSString * username =
        [NSString stringWithFormat:[[self class] usernameFormatString],
        user.username];
    if (!self.highlighted) {
    	// draw white drop shadows
    	if ([SettingsReader displayTheme] == kDisplayThemeLight) {
        	[[UIColor whiteColor] set];
        	point = CGPointMake(boundsX + LEFT_MARGIN, TOP_MARGIN + 1);
        	[user.name drawAtPoint:point forWidth:labelWidth
        	    withFont:nameLabelFont minFontSize:NAME_LABEL_FONT_SIZE
        	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
        	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
        	point =
        	    CGPointMake(boundsX + LEFT_MARGIN, USERNAME_TOP_MARGIN + 1);
        	[username drawAtPoint:point forWidth:labelWidth
        	    withFont:usernameLabelFont minFontSize:USERNAME_LABEL_FONT_SIZE
        	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
        	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
        	point =
        	    CGPointMake(boundsX + LEFT_MARGIN, FOLLOWERS_TOP_MARGIN + 1);
            [[user followersDescription] drawAtPoint:point forWidth:labelWidth
        	    withFont:followersLabelFont
        	    minFontSize:FOLLOWERS_LABEL_FONT_SIZE
        	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
        	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
	    }
    }

	[nameLabelTextColor set];
	point =
	    CGPointMake(boundsX + LEFT_MARGIN, TOP_MARGIN);
	[user.name drawAtPoint:point forWidth:labelWidth
	    withFont:nameLabelFont minFontSize:NAME_LABEL_FONT_SIZE
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

	[usernameLabelTextColor set];
	point =
	    CGPointMake(boundsX + LEFT_MARGIN, USERNAME_TOP_MARGIN);
	[username drawAtPoint:point forWidth:labelWidth
	    withFont:usernameLabelFont minFontSize:USERNAME_LABEL_FONT_SIZE
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

	[followersLabelTextColor set];
	point =
	    CGPointMake(boundsX + LEFT_MARGIN, FOLLOWERS_TOP_MARGIN);
    [[user followersDescription] drawAtPoint:point forWidth:labelWidth
	    withFont:followersLabelFont minFontSize:FOLLOWERS_LABEL_FONT_SIZE
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

	point =
        CGPointMake(boundsX + AVATAR_BACKGROUND_LEFT_MARGIN,
        AVATAR_BACKGROUND_TOP_MARGIN);
    [[[self class] avatarBackgroundImage] drawAtPoint:point];

    CGRect avatarRect =
        CGRectMake(AVATAR_LEFT_MARGIN, AVATAR_TOP_MARGIN,
        AVATAR_WIDTH, AVATAR_HEIGHT);
    [avatar drawInRect:avatarRect withRoundedCornersWithRadius:6.0];
}

- (void)setUser:(User *)aUser
{
    [aUser retain];
    [user release];
    user = aUser;

    [self setNeedsDisplay];
}

- (void)setAvatar:(UIImage *)anAvatar
{
    [anAvatar retain];
    [avatar release];
    avatar = anAvatar;

    [self setNeedsDisplay];
}

+ (NSString *)usernameFormatString
{
    if (!usernameFormatString) {
        usernameFormatString = @"@%@";
        [usernameFormatString retain];
    }

    return usernameFormatString;
}

+ (UIColor *)lighterTextColor
{
    if (!lighterTextColor)
        lighterTextColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor twitchLightLightGrayColor] :
            [[UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1] retain];

    return lighterTextColor;
}

+ (UIColor *)darkerTextColor
{
    if (!darkerTextColor)
        darkerTextColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor whiteColor] : [UIColor blackColor];

    return darkerTextColor;
}

+ (UIImage *)avatarBackgroundImage
{
    if (!avatarBackgroundImage)
        avatarBackgroundImage =
            [[UIImage imageNamed:@"AvatarBackground.png"] retain];

    return avatarBackgroundImage;
}

@end
