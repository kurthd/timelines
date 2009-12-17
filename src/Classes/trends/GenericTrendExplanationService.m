//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "GenericTrendExplanationService.h"

@implementation GenericTrendExplanationService

@synthesize delegate;

- (void)dealloc
{
    self.delegate = nil;
    [serviceUrl release];

    [super dealloc];
}

- (id)initWithServiceUrl:(NSURL *)url
{
    if (self = [super init])
        serviceUrl = [url copy];

    return self;
}

#pragma mark Public implementation

- (void)fetchCurrentTrends
{
    [AsynchronousNetworkFetcher fetcherWithUrl:serviceUrl delegate:self];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString * json = [[NSString alloc] initWithData:data encoding:encoding];

    NSError * error = nil;
    NSDictionary * parsedJson = [json JSONValueOrError:&error];
    if (error)
        [self fetcher:fetcher failedToReceiveDataFromUrl:url error:error];
    else {
        NSArray * rawTrends = [parsedJson objectForKey:@"trends"];
        NSMutableArray * trends =
            [NSMutableArray arrayWithCapacity:rawTrends.count];
        for (NSDictionary * rawTrend in rawTrends) {
            Trend * trend = [[Trend alloc] init];

            // Don't know what kind of objects we're going to get here, so be
            // excessively defensive.

            NSString * name = [rawTrend objectForKey:@"name"];
            trend.name = [name isKindOfClass:[NSString class]] ? name : @"";

            NSString * explanation = nil;
            id description = [rawTrend objectForKey:@"description"];
            if ([description isKindOfClass:[NSDictionary class]])
                explanation = [description objectForKey:@"text"];
            trend.explanation =
                [explanation isKindOfClass:[NSString class]] ?
                explanation :
                @"";

            NSString * query = [rawTrend objectForKey:@"query"];
            trend.query = [query isKindOfClass:[NSString class]] ? query : @"";

            if (trend.name && trend.query)
                [trends addObject:trend];

            [trend release];
        }

        [self.delegate service:self didFetchTrends:trends];
    }

    [json release];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    [self.delegate service:self failedToFetchTrends:error];
}

@end

@implementation GenericTrendExplanationService (CreationHelpers)

+ (id)serviceWithServiceUrlString:(NSString *)urlString
{
    NSURL * url = [NSURL URLWithString:urlString];
    return [[[self alloc] initWithServiceUrl:url] autorelease];
}

+ (id)whatTheTrendService
{
    static NSString * serviceUrl =
        @"http://api.whatthetrend.com/api/v2/trends.json";
    return [self serviceWithServiceUrlString:serviceUrl];
}

+ (id)letsBeTrendsService
{
    static NSString * serviceUrl =
        @"http://letsbetrends.com/api/current_trends";
    return [self serviceWithServiceUrlString:serviceUrl];
}

@end
