//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "GenericTrendExplanationService.h"

@implementation GenericTrendExplanationService

@synthesize delegate, serviceUrl, webUrl;

- (void)dealloc
{
    self.delegate = nil;
    [serviceUrl release];
    [webUrl release];

    [super dealloc];
}

- (id)initWithServiceUrl:(NSURL *)aServiceUrl webUrl:(NSURL *)aWebUrl
{
    if (self = [super init]) {
        serviceUrl = [aServiceUrl copy];
        webUrl = [aWebUrl copy];
    }

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

+ (id)serviceWithServiceUrlString:(NSString *)serviceUrlString
                     webUrlString:(NSString *)webUrlString
{
    NSURL * serviceUrl = [NSURL URLWithString:serviceUrlString];
    NSURL * webUrl = [NSURL URLWithString:webUrlString];
    id service = [[self alloc] initWithServiceUrl:serviceUrl webUrl:webUrl];

    return [service autorelease];
}

+ (id)whatTheTrendService
{
    static NSString * serviceUrl =
        @"http://api.whatthetrend.com/api/v2/trends.json";
    static NSString * webUrl = @"http://whatthetrend.com";
    return [self serviceWithServiceUrlString:serviceUrl webUrlString:webUrl];
}

+ (id)letsBeTrendsService
{
    static NSString * serviceUrl =
        @"http://letsbetrends.com/api/current_trends";
    static NSString * webUrl = @"http://letsbetrends.com";
    return [self serviceWithServiceUrlString:serviceUrl webUrlString:webUrl];
}

@end
