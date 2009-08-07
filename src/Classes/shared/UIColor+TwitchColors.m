//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UIColor+TwitchColors.h"

@implementation UIColor (TwitchColors)

static UIColor * twitchBlueColor;
static UIColor * twitchGrayColor;
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

+ (UIColor *)twitchBlueColor
{
    if (!twitchBlueColor)
        twitchBlueColor =
            [[UIColor colorWithRed:0 green:.4 blue:.8 alpha:1] retain];

    return twitchBlueColor;
}

+ (UIColor *)twitchGrayColor
{
    if (!twitchGrayColor)
        twitchGrayColor =
            [[UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1] retain];

    return twitchGrayColor;
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
    if (!twitchBackgroundColor)
        twitchBackgroundColor =
            [[UIColor colorWithRed:.909 green:.909 blue:.909 alpha:1] retain];

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

@end
