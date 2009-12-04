//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitbitShared.h"

@class TimelineDisplayMgr, SearchDisplayMgr;

@interface TrendDisplayMgr : NSObject
{
    UINavigationController * navigationController;
    TimelineDisplayMgr * timelineDisplayMgr;
    SearchDisplayMgr * searchDisplayMgr;
}

- (id)initWithSearchDisplayMgr:(SearchDisplayMgr *)aSearchDisplayMgr
          navigationController:(UINavigationController *)aNavicationController
            timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr;


- (void)displayTrend:(Trend *)trend;

@end
