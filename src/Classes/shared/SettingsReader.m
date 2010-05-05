//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "SettingsReader.h"
#import "UIApplication+ConfigurationAdditions.h"

@implementation SettingsReader

static BOOL alreadyReadFetchQuantityValue;
static NSInteger fetchQuantity;

static BOOL alreadyReadShortenURLsValue;
static BOOL shortenURLs;

static BOOL alreadyReadImageQualityValue;
static ComposeTweetImageQuality imageQuality;

static BOOL alreadyReadNearbySearchRadiusValue;
static NSInteger nearbySearchRadius;

static BOOL scrollToTopValueAlreadyRead;
static BOOL scrollToTop;

static NSInteger retweetFormatValueAlredyRead;
static NSInteger retweetFormat;

static BOOL alreadyReadFontSizeValue;
static NSInteger timelineFontSize;

+ (NSInteger)fetchQuantity
{
    if (!alreadyReadFetchQuantityValue) {
        alreadyReadFetchQuantityValue = YES;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        fetchQuantity = [defaults integerForKey:@"fetch_quantity"];
        if (fetchQuantity == 0)
            fetchQuantity = [[self class] defaultFetchQuantity];
    }
    
    return fetchQuantity;
}

+ (NSInteger)defaultFetchQuantity
{
    return 20;
}

+ (BOOL)shortenURLs
{
    if (!alreadyReadShortenURLsValue) {
        alreadyReadShortenURLsValue = YES;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        shortenURLs = defaults ? [defaults boolForKey:@"shorten_urls"] : YES;
    }

    return shortenURLs;
}

+ (ComposeTweetImageQuality)imageQuality
{
    if (!alreadyReadImageQualityValue) {
        alreadyReadImageQualityValue = YES;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        imageQuality =
            defaults ?
            [defaults integerForKey:@"image_quality"] :
            kComposeTweetImageQualityMedium;
    }

    return imageQuality;
}

+ (NSInteger)nearbySearchRadius
{
    if (!alreadyReadNearbySearchRadiusValue) {
        alreadyReadNearbySearchRadiusValue = YES;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        nearbySearchRadius = [defaults integerForKey:@"search_radius"];
        if (nearbySearchRadius == 0)
            nearbySearchRadius = [[self class] defaultNearbySearchRadius];
    }

    return nearbySearchRadius;
}

+ (NSInteger)defaultNearbySearchRadius
{
    return 10;
}

+ (DisplayTheme)displayTheme
{
    return kDisplayThemeDark;
}

+ (BOOL)scrollToTop
{
    if (!scrollToTopValueAlreadyRead) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        scrollToTop = [defaults boolForKey:@"scroll_to_top"];
        scrollToTopValueAlreadyRead = YES;
    }
    
    return scrollToTop;
}

+ (NSInteger)retweetFormat
{
    if (!retweetFormatValueAlredyRead) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        retweetFormat = [defaults integerForKey:@"retweet_format"];
        retweetFormatValueAlredyRead = YES;
    }

    return retweetFormat;
}

+ (BOOL)showAds
{
    return [[UIApplication sharedApplication] isLiteVersion];
}

+ (TimelineFontSize)timelineFontSize
{
    if (!alreadyReadFontSizeValue) {
        alreadyReadFontSizeValue = YES;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        timelineFontSize =
            defaults ?
            [defaults integerForKey:@"font_size"] :
            kTimelineFontSizeMedium;
    }

    return timelineFontSize;
}

@end
