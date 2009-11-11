//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTrendsResponseProcessor.h"
#import "Trend.h"

@interface FetchTrendsResponseProcessor ()

@property (nonatomic, assign) TrendFetchType trendType;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation FetchTrendsResponseProcessor

@synthesize trendType, delegate;

+ (id)processorWithTrendFetchType:(TrendFetchType)aTrendFetchType
                         delegate:(id<TwitterServiceDelegate>)aDelegate
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
                    delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.trendType = aTrendFetchType;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)rawResults
{
    if (!rawResults)
        return NO;

    NSDictionary * results = [rawResults objectAtIndex:0];
    NSDictionary * trendsWrapper = [results objectForKey:@"trends"];

    // The 'trendsWrapper' dictionary contains one entry, with the date as the
    //  key
    NSArray * allTrends =
        [trendsWrapper objectForKey:[[trendsWrapper allKeys] objectAtIndex:0]];

    NSMutableArray * trends =
        [NSMutableArray arrayWithCapacity:allTrends.count];
    for (NSDictionary * result in allTrends) {
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
    [delegate performSelector:sel withObject:trends];

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
    [delegate performSelector:sel withObject:error];

    return YES;
}

@end
