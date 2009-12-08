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

    id selectionTarget;
    SEL selectionAction;

    id explanationTarget;
    SEL explanationAction;
}

@property(nonatomic, assign) id selectionTarget;
@property(nonatomic, assign) SEL selectionAction;

@property(nonatomic, assign) id explanationTarget;
@property(nonatomic, assign) SEL explanationAction;

@property (nonatomic, retain) NetworkAwareViewController * netController;

@end
