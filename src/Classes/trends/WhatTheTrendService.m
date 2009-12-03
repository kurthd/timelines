//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "WhatTheTrendService.h"

@interface WhatTheTrendService ()
+ (NSURL *)whatTheTrendUrl;
@end

@implementation WhatTheTrendService

@synthesize delegate;

- (void)dealloc
{
    self.delegate = nil;

    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

#pragma mark Public implementation

- (void)fetchCurrentTrends
{
    NSURL * url = [[self class] whatTheTrendUrl];
    [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];
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
        NSLog(@"JSON: %@", parsedJson);

        NSArray * rawTrends = [parsedJson objectForKey:@"trends"];
        NSMutableArray * trends =
            [NSMutableArray arrayWithCapacity:rawTrends.count];
        for (NSDictionary * rawTrend in rawTrends) {
            Trend * trend = [[Trend alloc] init];

            trend.name = [rawTrend objectForKey:@"name"];
            trend.explanation =
                [[rawTrend objectForKey:@"description"] objectForKey:@"text"];
            trend.query = [rawTrend objectForKey:@"query"];

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

#pragma mark Private implementation

+ (NSURL *)whatTheTrendUrl
{
    static NSString * urlString =
        @"http://api.whatthetrend.com/api/v2/trends.json";

    return [NSURL URLWithString:urlString];
}

@end
