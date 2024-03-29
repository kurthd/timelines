//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UIColor+TwitchColors.h"
#import "SettingsReader.h"

@implementation UIColor (TwitchColors)

static UIColor * twitchBlueColor;
static UIColor * twitchBlueOnDarkBackgroundColor;
static UIColor * twitchGrayColor;
static UIColor * twitchLightGrayColor;
static UIColor * twitchLightLightGrayColor;
static UIColor * twitchDarkGrayColor;
static UIColor * twitchDarkDarkGrayColor;
static UIColor * twitchLabelColor;
static UIColor * twitchBackgroundColor;
static UIColor * twitchResolvedColor;
static UIColor * twitchNewColor;
static UIColor * twitchOpenColor;
static UIColor * twitchHoldColor;
static UIColor * twitchInvalidColor;
static UIColor * twitchRoundedRectBackgroundColor;
static UIColor * twitchSelectedCellColor;
static UIColor * twitchCheckedColor;
static UIColor * selectedTableViewCellBackgroundColor;
static UIColor * darkCellBackgroundColor;
static UIColor * mentionCellColor;
static UIColor * defaultDarkThemeCellColor;

+ (UIColor *)twitchBlueColor
{
    if (!twitchBlueColor)
        twitchBlueColor =
            [[UIColor colorWithRed:.141 green:.439 blue:.847 alpha:1] retain];

    return twitchBlueColor;
}

+ (UIColor *)twitchBlueOnDarkBackgroundColor
{
    if (!twitchBlueOnDarkBackgroundColor)
        twitchBlueOnDarkBackgroundColor =
            [[UIColor colorWithRed:.447 green:.627 blue:.773 alpha:1] retain];

    return twitchBlueOnDarkBackgroundColor;
}

+ (UIColor *)twitchGrayColor
{
    if (!twitchGrayColor)
        twitchGrayColor =
            [[UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1] retain];

    return twitchGrayColor;
}

+ (UIColor *)twitchLightGrayColor
{
    if (!twitchLightGrayColor)
        twitchLightGrayColor =
            [[UIColor colorWithRed:.75 green:.75 blue:.75 alpha:1] retain];

    return twitchLightGrayColor;
}

+ (UIColor *)twitchLightLightGrayColor
{
    if (!twitchLightLightGrayColor)
        twitchLightLightGrayColor =
            [[UIColor colorWithRed:.85 green:.85 blue:.85 alpha:1] retain];

    return twitchLightLightGrayColor;
}

+ (UIColor *)twitchDarkGrayColor
{
    if (!twitchDarkGrayColor)
        twitchDarkGrayColor =
            [[UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1] retain];

    return twitchDarkGrayColor;
}

+ (UIColor *)twitchDarkDarkGrayColor
{
    if (!twitchDarkDarkGrayColor)
        twitchDarkDarkGrayColor =
            [[UIColor colorWithRed:.18 green:.18 blue:.18 alpha:1] retain];

    return twitchDarkDarkGrayColor; 
}

+ (UIColor *)twitchLabelColor
{
    if (!twitchLabelColor)
        twitchLabelColor =
            [[UIColor colorWithRed:.318 green:.4 blue:.569 alpha:1] retain];

    return twitchLabelColor;
}

+ (UIColor *)twitchBackgroundColor
{
    if (!twitchBackgroundColor) {
        twitchBackgroundColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [[UIColor colorWithPatternImage:
            [UIImage imageNamed:@"DarkThemeBackground.png"]] retain] :
            [[UIColor groupTableViewBackgroundColor] retain];
    }

    return twitchBackgroundColor;
}

+ (UIColor *)twitchResolvedColor
{
    if (!twitchResolvedColor)
        twitchResolvedColor =
            [[UIColor colorWithRed:.4 green:.667 blue:0 alpha:1] retain];

    return twitchResolvedColor;
}

+ (UIColor *)twitchNewColor
{
    if (!twitchNewColor)
        twitchNewColor =
            [[UIColor colorWithRed:1 green:.067 blue:.467 alpha:1] retain];

    return twitchNewColor;
}

+ (UIColor *)twitchOpenColor
{
    if (!twitchOpenColor)
        twitchOpenColor =
            [[UIColor colorWithRed:.667 green:.667 blue:.667 alpha:1] retain];

    return twitchOpenColor;
}

+ (UIColor *)twitchHoldColor
{
    if (!twitchHoldColor)
        twitchHoldColor =
            [[UIColor colorWithRed:.933 green:.733 blue:0 alpha:1] retain];

    return twitchHoldColor;
}

+ (UIColor *)twitchInvalidColor
{
    if (!twitchInvalidColor)
        twitchInvalidColor =
            [[UIColor colorWithRed:.667 green:.2 blue:0 alpha:1] retain];

    return twitchInvalidColor;
}

+ (UIColor *)twitchRoundedRectBackgroundColor
{
    if (!twitchRoundedRectBackgroundColor)
        twitchRoundedRectBackgroundColor =
            [[UIColor colorWithRed:.549 green:.6 blue:.706 alpha:1] retain];

    return twitchRoundedRectBackgroundColor;
}

+ (UIColor *)twitchSelectedCellColor
{
    if (!twitchSelectedCellColor)
        twitchSelectedCellColor =
            [[UIColor colorWithRed:0.008 green:0.427 blue:0.925 alpha:1.0]
            retain];

    return twitchSelectedCellColor;
}

+ (UIColor *)twitchCheckedColor
{
    if (!twitchCheckedColor)
        twitchCheckedColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [[self class] twitchBlueOnDarkBackgroundColor] :
            [[UIColor colorWithRed:0.196 green:0.310 blue:0.522 alpha:1.0]
            retain];

    return twitchCheckedColor;
}

+ (UIColor *)selectedTableViewCellBackgroundColor
{
    if (!selectedTableViewCellBackgroundColor)
        selectedTableViewCellBackgroundColor =
            [[UIColor colorWithRed:.4 green:.388 blue:.910 alpha:1.0] retain];

    return selectedTableViewCellBackgroundColor;
}

+ (UIColor *)darkCellBackgroundColor
{
    if (!darkCellBackgroundColor)
        darkCellBackgroundColor =
            [[UIColor colorWithRed:.95 green:.95 blue:.95 alpha:1] retain];
    
    return darkCellBackgroundColor;
}

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

@end
