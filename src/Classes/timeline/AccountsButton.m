//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AccountsButton.h"
#import "UIColor+TwitchColors.h"
#import "UIImage+DrawingAdditions.h"
#import "SettingsReader.h"

@interface AccountsButton ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, readonly) RoundedImage * avatar;
@property (nonatomic, readonly) UIImage * dropDownArrow;
@property (nonatomic, readonly) UIImage * highlightedDropDownArrow;
@property (nonatomic, readonly) UIImage * avatarBackground;
@property (nonatomic, readonly) UIImageView * highlightedAvatarMask;

@end

@implementation AccountsButton

@synthesize username, avatar, action;

- (void)dealloc
{
    [username release];
    [avatar release];
    [dropDownArrow release];
    [highlightedDropDownArrow release];
    [avatarBackground release];
    [highlightedAvatarMask release];
    [super dealloc];
}

#pragma mark UIView overrides

- (void)drawRect:(CGRect)rect
{
#define OFFSET 20
#define AVATAR_WIDTH 27

    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);

    CGRect contentRect = self.bounds;

    CGPoint point;
    CGSize size;

    UIFont * usernameFont = [UIFont boldSystemFontOfSize:21.0];

    UIColor * usernameShadowColor =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor blackColor] : [UIColor twitchGrayColor];
    UIColor * usernameColor =
        self.highlighted ?
        [UIColor twitchLightLightGrayColor] : [UIColor whiteColor];

    size = [username sizeWithFont:usernameFont];
    CGFloat baseX = (contentRect.size.width - size.width + OFFSET ) / 2;

    [usernameShadowColor set];
    point = CGPointMake(baseX, 1);

	[username drawAtPoint:point forWidth:150
	    withFont:usernameFont minFontSize:18
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

    [usernameColor set];
    point = CGPointMake(baseX, 2);

	[username drawAtPoint:point forWidth:150
	    withFont:usernameFont minFontSize:18
	    actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
	    baselineAdjustment:UIBaselineAdjustmentAlignBaselines];

    CGRect dropDownArrowRect =
        CGRectMake((contentRect.size.width + size.width + OFFSET) / 2 + 3, 9,
        14, 14);
    if (self.highlighted)
        [self.highlightedDropDownArrow drawInRect:dropDownArrowRect];
    else
        [self.dropDownArrow drawInRect:dropDownArrowRect];

    CGRect avatarBackgroundRect = CGRectMake(baseX - 41, 0, 33, 33);
    [self.avatarBackground drawInRect:avatarBackgroundRect];

    self.highlightedAvatarMask.frame = CGRectMake(baseX - 40, 1, 31, 31);
    self.highlightedAvatarMask.hidden = !self.highlighted;

    CGRect avatarFrame = self.avatar.frame;
    avatarFrame.origin.x = baseX - 38;
    self.avatar.frame = avatarFrame;

    if (newUser) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
            forView:self.avatar cache:YES];
    }

    [super drawRect:rect];

    if (newUser)
        [UIView commitAnimations];

    newUser = NO;
}

#pragma mark UIControler overrides

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL returnVal = [super beginTrackingWithTouch:touch withEvent:event];

    self.highlighted = YES;
    [self setNeedsDisplay];

    return returnVal;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];

    self.highlighted = NO;
    [self setNeedsDisplay];
    
    [target performSelector:action withObject:nil];
}

#pragma mark Public interface implementation

- (void)setUsername:(NSString *)aUsername avatar:(UIImage *)anAvatar
{
    self.username = aUsername;
    [self.avatar setImage:anAvatar];

    newUser = YES;
    [self setNeedsDisplay];
}

#pragma mark Private method implementation

- (RoundedImage *)avatar
{
    if (!avatar) {
        avatar = [[RoundedImage alloc] initWithRadius:4];
        avatar.frame = CGRectMake(0, 3, 27, 27);
        avatar.backgroundColor = [UIColor clearColor];
        [self addSubview:avatar];
    }

    return avatar;
}

- (UIImage *)dropDownArrow
{
    if (!dropDownArrow)
        dropDownArrow = [[UIImage imageNamed:@"DropDownArrow.png"] retain];

    return dropDownArrow;
}

- (UIImage *)highlightedDropDownArrow
{
    if (!highlightedDropDownArrow)
        highlightedDropDownArrow =
            [[UIImage imageNamed:@"DropDownArrowHighlighted.png"] retain];

    return highlightedDropDownArrow;
}

- (UIImageView *)highlightedAvatarMask
{
    if (!highlightedAvatarMask) {
        UIImage * highlightedAvatarMaskImage =
            [UIImage imageNamed:@"AccountsAvatarMask.png"];
        highlightedAvatarMask =
            [[UIImageView alloc] initWithImage:highlightedAvatarMaskImage];
        CGRect maskFrame = highlightedAvatarMask.frame;
        maskFrame.origin.y = 0;
        highlightedAvatarMask.frame = maskFrame;
        [self addSubview:highlightedAvatarMask];
    }

    return highlightedAvatarMask;
}

- (UIImage *)avatarBackground
{
    if (!avatarBackground)
        avatarBackground =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [[UIImage imageNamed:@"AccountsAvatarBackgroundDark.png"] retain] :
            [[UIImage imageNamed:@"AccountsAvatarBackground.png"] retain];

    return avatarBackground;
}

@end
