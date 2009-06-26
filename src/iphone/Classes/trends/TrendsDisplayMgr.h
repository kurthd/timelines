//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterService.h"
#import "TrendsViewController.h"
#import "NetworkAwareViewController.h"

@interface TrendsDisplayMgr : NSObject
    <TwitterServiceDelegate, NetworkAwareViewControllerDelegate,
    TrendsViewControllerDelegate>
{
    TwitterService * service;

    NetworkAwareViewController * networkAwareViewController;
    TrendsViewController * trendsViewController;
    UISegmentedControl * segmentedControl;

    NSMutableArray * allTrends;
}

- (id)initWithTwitterService:(TwitterService *)aService
          netAwareController:(NetworkAwareViewController *)navc;

@end
