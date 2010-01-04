//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKPlacemark.h>

@interface CoordRecentHistoryCache : NSObject <NSFastEnumeration>
{
    NSMutableDictionary * recentlyViewed;
    
    // Helpers for managing history
    NSMutableArray * history;
    NSMutableDictionary * historyAppearances;
    
    NSInteger cacheLimit;
}

+ (CoordRecentHistoryCache *)instance;

- (id)initWithCacheLimit:(NSInteger)cacheLimit;

- (void)setObject:(MKPlacemark *)anObject forKey:(CLLocation *)aKey;
- (id)objectForKey:(id)aKey;

- (NSDictionary *)allRecentlyViewed;

- (void)clear;

@end
