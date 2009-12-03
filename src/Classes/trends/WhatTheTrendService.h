//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitbitShared.h"

@protocol WhatTheTrendServiceDelegate;

@interface WhatTheTrendService : NSObject <AsynchronousNetworkFetcherDelegate>
{
    id<WhatTheTrendServiceDelegate> delegate;
}

@property (nonatomic, assign) id<WhatTheTrendServiceDelegate> delegate;

- (void)fetchCurrentTrends;

@end


@protocol WhatTheTrendServiceDelegate

- (void)service:(WhatTheTrendService *)service didFetchTrends:(NSArray *)trends;
- (void)service:(WhatTheTrendService *)service failedToFetchTrends:(NSError *)e;

@end
