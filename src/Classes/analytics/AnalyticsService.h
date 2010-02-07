//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface AnalyticsService : NSObject
{
}

- (void)startAnalytics;
- (void)stopAnalytics;

- (void)setLocation:(CLLocation *)location;

@end
