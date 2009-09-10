//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "SettingsReader.h"

@implementation SettingsReader

static BOOL alreadyReadFetchQuantityValue;
static NSInteger fetchQuantity;

static BOOL alreadyReadShortenURLsValue;
static BOOL shortenURLs;

static BOOL alreadyReadImageQualityValue;
static ComposeTweetImageQuality imageQuality;

static BOOL alreadyReadNearbySearchRadiusValue;
static NSInteger nearbySearchRadius;

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
            nearbySearchRadius = [[self class] defaultFetchQuantity];
    }

    return nearbySearchRadius;
}

+ (NSInteger)defaultNearbySearchRadius
{
    return 10;
}

@end
