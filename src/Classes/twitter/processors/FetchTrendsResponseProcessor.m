//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTrendsResponseProcessor.h"
#import "Trend.h"

@interface FetchTrendsResponseProcessor ()

@property (nonatomic, assign) TrendFetchType trendType;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchTrendsResponseProcessor

@synthesize trendType, delegate;

+ (id)processorWithTrendFetchType:(TrendFetchType)aTrendFetchType
                         delegate:(id)aDelegate
{
    return [[[[self class] alloc] initWithTrendFetchType:aTrendFetchType
                                           delegate:aDelegate] autorelease];
}

- (void)dealloc
{
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTrendFetchType:(TrendFetchType)aTrendFetchType
                    delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.trendType = aTrendFetchType;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)results
{
    if (!results)
        return NO;

    NSMutableArray * trends = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary * result in results) {
        Trend * trend = [[Trend alloc] init];

        trend.name = [result objectForKey:@"name"];
        trend.query = [result objectForKey:@"query"];

        if (trend.name && trend.query)
            [trends addObject:trend];

        [trend release];
    }

    SEL sel;
    switch (trendType) {
        case kFetchCurrentTrends:
            sel = @selector(fetchedCurrentTrends:);
            break;
        case kFetchDailyTrends:
            sel = @selector(fetchedDailyTrends:);
            break;
        case kFetchWeeklyTrends:
            sel = @selector(fetchedWeeklyTrends:);
            break;
    }
    [self invokeSelector:sel withTarget:delegate args:trends, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel;
    switch (trendType) {
        case kFetchCurrentTrends:
            sel = @selector(failedToFetchCurrentTrends:);
            break;
        case kFetchDailyTrends:
            sel = @selector(failedToFetchDailyTrends:);
            break;
        case kFetchWeeklyTrends:
            sel = @selector(failedToFetchWeeklyTrends:);
            break;
    }
    [self invokeSelector:sel withTarget:delegate args:error, nil];

    return YES;
}

@end
