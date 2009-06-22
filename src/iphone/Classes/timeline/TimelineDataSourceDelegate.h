//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TimelineDataSourceDelegate

- (void)timeline:(NSArray *)aTimeline
    fetchedSinceUpdateId:(NSNumber *)anUpdateId page:(NSNumber *)page;

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error;

@end
