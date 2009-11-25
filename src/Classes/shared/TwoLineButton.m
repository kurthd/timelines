//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwoLineButton.h"
#import "SettingsReader.h"
#import "UIColor+TwitchColors.h"

@interface TwoLineButton ()

+ (UIImage *)backgroundImage;

@property (nonatomic, copy) NSString * lineOne;
@property (nonatomic, copy) NSString * lineTwo;

@end

@implementation TwoLineButton

static UIImage * backgroundImage;

@synthesize action;
@synthesize lineOne, lineTwo;

- (void)dealloc
{
    [lineOne release];
    [lineTwo release];
    [super dealloc];
}

- (void)awakeFromNib
{
    self.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
    self.contentMode = UIViewContentModeTopLeft;
}

- (void)setLineOne:(NSString * )lineOneText lineTwo:(NSString *)lineTwoText
{
    self.lineOne = lineOneText;
    self.lineTwo = lineTwoText;
}

#pragma mark UIView overrides

- (void)drawRect:(CGRect)rect
{
    if (self.highlighted)
        [[[UIImage imageNamed:@"StandardButtonBackgroundHighlighted.png"]
            stretchableImageWithLeftCapWidth:11 topCapHeight:0]
            drawInRect:self.bounds];
    else
        [[[self class] backgroundImage] drawInRect:self.bounds];

    UIFont * font = [UIFont boldSystemFontOfSize:13.0];

    UIColor * textColor;
    if (self.highlighted)
        textColor = [UIColor whiteColor];
    else if ([SettingsReader displayTheme] == kDisplayThemeDark)
        textColor =
            self.enabled ?
            [UIColor twitchBlueOnDarkBackgroundColor] :
            [UIColor twitchGrayColor];
    else
        textColor =
            self.enabled ? [UIColor twitchLabelColor] : [UIColor grayColor];

    [textColor set];
    CGSize size = [lineOne sizeWithFont:font];
    CGPoint point = CGPointMake((self.bounds.size.width - size.width) / 2 , 6);
    [lineOne drawAtPoint:point withFont:font];

    size = [lineTwo sizeWithFont:font];    
    point = CGPointMake((self.bounds.size.width - size.width) / 2 , 21);
    [lineTwo drawAtPoint:point withFont:font];
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

#pragma mark Helper methods

+ (UIImage *)backgroundImage
{
    if (!backgroundImage) {
        UIImage * unstretchableImage =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIImage imageNamed:@"StandardButtonBackgroundDarkTheme.png"] :
            [UIImage imageNamed:@"StandardButtonBackground.png"];
            backgroundImage =
                [[unstretchableImage stretchableImageWithLeftCapWidth:11
                topCapHeight:0]
                retain];
    }

    return backgroundImage;
}

@end
