//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kComposeTweetImageQualityLow,
    kComposeTweetImageQualityMedium,
    kComposeTweetImageQualityHigh
} ComposeTweetImageQuality;

typedef enum {
    kDisplayThemeLight,
    kDisplayThemeDark
} DisplayTheme;

@interface SettingsReader : NSObject

+ (NSInteger)fetchQuantity;
+ (NSInteger)defaultFetchQuantity;
+ (BOOL)shortenURLs;
+ (ComposeTweetImageQuality)imageQuality;
+ (NSInteger)nearbySearchRadius;
+ (DisplayTheme)displayTheme;
+ (NSInteger)defaultNearbySearchRadius;
+ (NSInteger)defaultNearbySearchRadius;

@end
