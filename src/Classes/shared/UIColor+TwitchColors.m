//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UIColor+TwitchColors.h"

@implementation UIColor (TwitchColors)

+ (UIColor *)twitchBlueColor
{
    return [UIColor colorWithRed:0 green:.4 blue:.8 alpha:1];
}

+ (UIColor *)twitchGrayColor
{
    return [UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1];
}

+ (UIColor *)twitchLabelColor
{
    return [UIColor colorWithRed:.318 green:.4 blue:.569 alpha:1];
}

+ (UIColor *)twitchBackgroundColor
{
    return [UIColor colorWithRed:.909 green:.909 blue:.909 alpha:1];
//    return [UIColor colorWithRed:.925 green:.933 blue:.953 alpha:1];
}

+ (UIColor *)twitchResolvedColor
{
    return [UIColor colorWithRed:.4 green:.667 blue:0 alpha:1];
}

+ (UIColor *)twitchNewColor
{
    return [UIColor colorWithRed:1 green:.067 blue:.467 alpha:1];
}

+ (UIColor *)twitchOpenColor
{
    return [UIColor colorWithRed:.667 green:.667 blue:.667 alpha:1];
}

+ (UIColor *)twitchHoldColor
{
    return [UIColor colorWithRed:.933 green:.733 blue:0 alpha:1];
}

+ (UIColor *)twitchInvalidColor
{
    return [UIColor colorWithRed:.667 green:.2 blue:0 alpha:1];
}

+ (UIColor *)twitchRoundedRectBackgroundColor
{
    return [UIColor colorWithRed:.549 green:.6 blue:.706 alpha:1];
}

+ (UIColor *)twitchSelectedCellColor
{
    return [UIColor colorWithRed:0.008 green:0.427 blue:0.925 alpha:1.0];
}

+ (UIColor *)twitchCheckedColor
{
    return [UIColor colorWithRed:0.196 green:0.310 blue:0.522 alpha:1.0];
}

+ (UIColor *)selectedTableViewCellBackgroundColor
{
    return [UIColor colorWithRed:.4 green:.388 blue:.910 alpha:1.0];
}

@end
