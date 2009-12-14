//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitbitAdMobDelegate.h"
#import "InfoPlistConfigReader.h"
#import "SettingsReader.h"

@implementation TwitbitAdMobDelegate

- (void)dealloc
{
    [publisherId release];
    [super dealloc];
}

- (NSString *)publisherId {
    if (!publisherId) {
        InfoPlistConfigReader * configReader = [InfoPlistConfigReader reader];
        publisherId = [configReader valueForKey:@"AdMobPublisherId"];
    }

    return publisherId;
}

- (UIColor *)adBackgroundColor {
    return [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor colorWithRed:.16 green:.16 blue:.16 alpha:1] :
        [UIColor colorWithRed:.718 green:.753 blue:.776 alpha:1];
}

- (UIColor *)primaryTextColor {
    return [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor colorWithRed:.447 green:.627 blue:.773 alpha:1] :
        [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
}

- (UIColor *)secondaryTextColor {
    return [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor colorWithRed:.447 green:.627 blue:.773 alpha:1] :
        [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
}

@end
