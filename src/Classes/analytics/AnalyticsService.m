//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import "AnalyticsService.h"
#import "TwitbitShared.h"
#import "Beacon.h"

@interface AnalyticsService ()
+ (NSString *)applicationCode;
+ (NSString *)twitbitApplicationCode;
+ (NSString *)twitbitLiteApplicationCode;
@end

@implementation AnalyticsService

- (void)startAnalytics
{
    NSString * applicationCode = [[self class] applicationCode];
    [Beacon initAndStartBeaconWithApplicationCode:applicationCode
                                  useCoreLocation:NO
                                      useOnlyWiFi:NO
                                  enableDebugMode:YES];
    
}

- (void)stopAnalytics
{
    [Beacon endBeacon];
}

#pragma mark Private implementation

+ (NSString *)applicationCode
{
    return [[UIApplication sharedApplication] isLiteVersion] ?
        [self twitbitLiteApplicationCode] : [self twitbitApplicationCode];
}

+ (NSString *)twitbitApplicationCode
{
    return @"b1250b1119134465064eee562002d7f8";
}

+ (NSString *)twitbitLiteApplicationCode
{
    return @"2be07675f83d0fefc430078be1874f89";
}

@end
