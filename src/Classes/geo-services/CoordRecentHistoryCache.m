//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "CoordRecentHistoryCache.h"

@interface TwitbitCoordinate : NSObject
{
    double longitude;
    double latitude;
}

@property (nonatomic, readonly) double longitude;
@property (nonatomic, readonly) double latitude;

- (id)initWithLatitude:(double)lat longitude:(double)lon;

@end

@interface CoordRecentHistoryCache (private)

+ (TwitbitCoordinate *)roundCoordinate:(CLLocation *)unroundedKey;

@end

@implementation TwitbitCoordinate

@synthesize longitude, latitude;

- (id)initWithLatitude:(double)lat longitude:(double)lon
{
    if (self = [super init]) {
        longitude = lon;
        latitude = lat;
    }

    return self;
}

- (BOOL)isEqual:(id)other
{
    TwitbitCoordinate * otherCoord = (TwitbitCoordinate *)other;

    return otherCoord &&
            self.longitude == otherCoord.longitude &&
            self.latitude == otherCoord.latitude;
}

- (NSUInteger)hash
{
    NSUInteger result = 17;
    result = 37 * result + latitude * 1000;
    result = 37 * result + longitude * 1000;

    return result;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end

@implementation CoordRecentHistoryCache

static CoordRecentHistoryCache * gInstance = NULL;

+ (CoordRecentHistoryCache *)instance
{
    @synchronized (self) {
        if (gInstance == NULL)
            gInstance = [[CoordRecentHistoryCache alloc] init];
    }

    return gInstance;
}

- (void)dealloc
{
    [recentlyViewed release];
    [history release];
    [historyAppearances release];
    [super dealloc];
}

- (id)init
{
    return [self initWithCacheLimit:20];
}

- (id)initWithCacheLimit:(NSInteger)aCacheLimit
{
    if (self = [super init]) {
        recentlyViewed = [[NSMutableDictionary alloc] init];
        history = [[NSMutableArray alloc] init];
        historyAppearances = [[NSMutableDictionary alloc] init];
        cacheLimit = aCacheLimit;
    }

    return self;
}

- (void)setObject:(MKPlacemark *)anObject forKey:(CLLocation *)unroundedKey
{
    TwitbitCoordinate * aKey = [[self class] roundCoordinate:unroundedKey];
    [recentlyViewed setObject:anObject forKey:aKey];

    [history insertObject:aKey atIndex:0];

    NSNumber * numAppearances = [historyAppearances objectForKey:aKey];
    if (numAppearances) {
        NSInteger appearancesAsInt = [numAppearances integerValue] + 1;
        numAppearances = [NSNumber numberWithInteger:appearancesAsInt];
        [historyAppearances setObject:numAppearances forKey:aKey];
    } else
        [historyAppearances setObject:[NSNumber numberWithInteger:1]
            forKey:aKey];

    if ([history count] > cacheLimit) {
        id oldestKey = [[history objectAtIndex:cacheLimit] retain];
        [history removeObjectAtIndex:cacheLimit];
        NSInteger oldestNumAppearances =
            [[historyAppearances objectForKey:oldestKey] integerValue] - 1;
        
        if (oldestNumAppearances == 0) {
            [historyAppearances removeObjectForKey:oldestKey];
            [recentlyViewed removeObjectForKey:oldestKey];
        } else
            [historyAppearances
                setObject:[NSNumber numberWithInteger:oldestNumAppearances]
                forKey:oldestKey];

        [oldestKey release];
    }
}

- (id)objectForKey:(id)unroundedKey
{
    TwitbitCoordinate * aKey = [[self class] roundCoordinate:unroundedKey];

    return [recentlyViewed objectForKey:aKey];
}

- (NSDictionary *)allRecentlyViewed
{
    return [[recentlyViewed copy] autorelease];
}

- (void)clear
{
    [recentlyViewed removeAllObjects];
    [history removeAllObjects];
    [historyAppearances removeAllObjects];
}

+ (TwitbitCoordinate *)roundCoordinate:(CLLocation *)unroundedKey
{
    // round coordinate to the nearest thousandth
    NSInteger unroundedLatThousandths =
        (unroundedKey.coordinate.latitude + 0.0005) * 1000;
    NSInteger unroundedLongThousandths =
        (unroundedKey.coordinate.longitude + 0.0005) * 1000;
    double roundedLat = unroundedLatThousandths / 1000.0;
    double roundedLong = unroundedLongThousandths / 1000.0;

    return [[[TwitbitCoordinate alloc]
        initWithLatitude:roundedLat longitude:roundedLong]
        autorelease];
}

#pragma mark NSFastEnumeration implementation

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id *)stackbuf
                                    count:(NSUInteger)len
{
    return [recentlyViewed
        countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
