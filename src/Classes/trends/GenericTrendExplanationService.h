//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitbitShared.h"

@protocol GenericTrendExplanationServiceDelegate;

@interface GenericTrendExplanationService :
    NSObject <AsynchronousNetworkFetcherDelegate>
{
    id<GenericTrendExplanationServiceDelegate> delegate;
    NSURL * serviceUrl;
}

@property (nonatomic, assign) id<GenericTrendExplanationServiceDelegate>
    delegate;

- (id)initWithServiceUrl:(NSURL *)aUrl;

- (void)fetchCurrentTrends;

@end


@interface GenericTrendExplanationService (CreationHelpers)

+ (id)whatTheTrendService;
+ (id)letsBeTrendsService;

@end


@protocol GenericTrendExplanationServiceDelegate

- (void)service:(GenericTrendExplanationService *)service
    didFetchTrends:(NSArray *)trends;
- (void)service:(GenericTrendExplanationService *)service
    failedToFetchTrends:(NSError *)e;

@end
