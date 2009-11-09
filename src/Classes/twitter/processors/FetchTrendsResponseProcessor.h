//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

typedef enum
{
    kFetchCurrentTrends,
    kFetchDailyTrends,
    kFetchWeeklyTrends
} TrendFetchType;

@interface FetchTrendsResponseProcessor : ResponseProcessor
{
    TrendFetchType trendType;
    id<TwitterServiceDelegate> delegate;
}

+ (id)processorWithTrendFetchType:(TrendFetchType)aTrendFetchType
                         delegate:(id<TwitterServiceDelegate>)aDelegate;

- (id)initWithTrendFetchType:(TrendFetchType)aTrendFetchType
                    delegate:(id<TwitterServiceDelegate>)aDelegate;
@end
