//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhatTheTrendService.h"

@class NetworkAwareViewController;

@interface TrendsViewController :
    UITableViewController <WhatTheTrendServiceDelegate>
{
    WhatTheTrendService * service;
    NSArray * trends;

    NetworkAwareViewController * netController;
}

@property (nonatomic, retain) NetworkAwareViewController * netController;

@end
