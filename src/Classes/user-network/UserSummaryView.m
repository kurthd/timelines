//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserSummaryView.h"
#import "User+UIAdditions.h"
#import "UIImage+DrawingAdditions.h"
#import "SettingsReader.h"
#import "UIColor+TwitchColors.h"

static const CGFloat AVATAR_ROUNDED_CORNER_RADIUS = 6.0;

@interface UserSummaryView ()

+ (NSString *)usernameFormatString;
+ (UIColor *)lighterTextColor;
+ (UIColor *)darkerTextColor;

+ (NSNumberFormatter *)formatter;

@end

@implementation UserSummaryView

static NSString * usernameFormatString;
static UIColor * lighterTextColor;
static UIColor * darkerTextColor;

static NSNumberFormatter * formatter;

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
#define LEFT_MARGIN 55
#define TOP_MARGIN 3
#define LABEL_WIDTH 237
#define LABEL_WIDTH_LANDSCAPE 397

#define NAME_LABEL_FONT_SIZE 18

#define USERNAME_LABEL_FONT_SIZE 15
#define USERNAME_TOP_MARGIN 5

#define FOLLOWERS_LABEL_FONT_SIZE 15
#define FOLLOWERS_TOP_MARGIN 25

#define LOCATION_LABEL_FONT_SIZE 14
#define LOCATION_TOP_MARGIN 40

#define AVATAR_WIDTH 48
#define AVATAR_HEIGHT 48

    UIColor * nameLabelTextColor = nil;
    UIFont * nameLabelFont = [UIFont boldSystemFontOfSize:NAME_LABEL_FONT_SIZE];

	UIColor * usernameLabelTextColor = nil;
	UIFont * usernameLabelFont =
	    [UIFont boldSystemFontOfSize:USERNAME_LABEL_FONT_SIZE];

	UIColor * followersLabelTextColor = nil;
	UIFont * followersLabelFont =
	    [UIFont systemFontOfSize:FOLLOWERS_LABEL_FONT_SIZE];
	UIFont * followersBoldLabelFont =
	    [UIFont boldSystemFontOfSize:FOLLOWERS_LABEL_FONT_SIZE];

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

	[nameLabelTextColor set];
	point =
	    CGPointMake(boundsX + LEFT_MARGIN, TOP_MARGIN);
	[user.username drawAtPoint:point forWidth:labelWidth
	    withFont:nameLabelFont minFontSize:NAME_LABEL_FONT_SIZE
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

    CGSize nameLabelSize = [user.username sizeWithFont:nameLabelFont];
	[usernameLabelTextColor set];
	point =
	    CGPointMake(boundsX + nameLabelSize.width + LEFT_MARGIN + 4,
	    USERNAME_TOP_MARGIN);
	[user.name drawAtPoint:point forWidth:labelWidth - nameLabelSize.width
	    withFont:usernameLabelFont minFontSize:USERNAME_LABEL_FONT_SIZE
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

    //
    // Draw following/followers label
    //
	[followersLabelTextColor set];
	point = CGPointMake(boundsX + LEFT_MARGIN, FOLLOWERS_TOP_MARGIN);

    NSString * followingCountString =
        [[[self class] formatter] stringFromNumber:user.friendsCount];
    [followingCountString drawAtPoint:point withFont:followersBoldLabelFont];

    CGSize size = [followingCountString sizeWithFont:followersBoldLabelFont];
    CGFloat width = size.width;
    point = CGPointMake(boundsX + LEFT_MARGIN + width, FOLLOWERS_TOP_MARGIN);

    NSString * followingFormatString = @" following, ";
    [followingFormatString drawAtPoint:point withFont:followersLabelFont];

    size = [followingFormatString sizeWithFont:followersLabelFont];
    width += size.width;
    point = CGPointMake(boundsX + LEFT_MARGIN + width, FOLLOWERS_TOP_MARGIN);

    NSString * followersCountString =
        [[[self class] formatter] stringFromNumber:user.followersCount];
    [followersCountString drawAtPoint:point withFont:followersBoldLabelFont];

    size = [followersCountString sizeWithFont:followersBoldLabelFont];
    width += size.width;
    point = CGPointMake(boundsX + LEFT_MARGIN + width, FOLLOWERS_TOP_MARGIN);

    NSString * followersFormatString = @" followers";
    [followersFormatString drawAtPoint:point withFont:followersLabelFont];

    CGRect avatarRect = CGRectMake(0, 0, AVATAR_WIDTH, AVATAR_HEIGHT);
    [avatar drawInRect:avatarRect];
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
            [UIColor twitchLightLightGrayColor] : [UIColor grayColor];

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

+ (NSNumberFormatter *)formatter
{
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }

    return formatter;
}

@end
