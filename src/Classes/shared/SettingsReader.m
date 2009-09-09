//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "SettingsReader.h"

@implementation SettingsReader

static BOOL alreadyReadFetchQuantityValue;
static NSInteger fetchQuantity;

static BOOL alreadyReadShortenURLsValue;
static BOOL shortenURLs;

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

+ (BOOL)shortenURLs
{
    if (!alreadyReadShortenURLsValue) {
        alreadyReadShortenURLsValue = YES;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        shortenURLs = defaults ? [defaults boolForKey:@"shorten_urls"] : YES;
    }

    return shortenURLs;
}

+ (NSInteger)defaultFetchQuantity
{
    return 20;
}

@end
