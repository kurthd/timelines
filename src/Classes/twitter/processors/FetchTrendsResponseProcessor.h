//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

typedef enum
{
    kFetchCurrentTrends,
    kFetchDailyTrends,
    kFetchWeeklyTrends
} TrendFetchType;

@interface FetchTrendsResponseProcessor : ResponseProcessor
{
    TrendFetchType trendType;
    id delegate;
}

+ (id)processorWithTrendFetchType:(TrendFetchType)aTrendFetchType
                         delegate:(id)aDelegate;

- (id)initWithTrendFetchType:(TrendFetchType)aTrendFetchType
                    delegate:(id)aDelegate;
@end
