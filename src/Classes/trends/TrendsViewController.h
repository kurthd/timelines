//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GenericTrendExplanationService.h"

@class NetworkAwareViewController;

@interface TrendsViewController :
    UITableViewController <GenericTrendExplanationServiceDelegate>
{
    GenericTrendExplanationService * service;
    NSArray * trends;

    NetworkAwareViewController * netController;

    id selectionTarget;
    SEL selectionAction;

    id explanationTarget;
    SEL explanationAction;

    BOOL lastDisplayedInLandscape;

    UIBarButtonItem * updatingTrendsActivityView;
    UIBarButtonItem * refreshButton;
}

@property(nonatomic, assign) id selectionTarget;
@property(nonatomic, assign) SEL selectionAction;

@property(nonatomic, assign) id explanationTarget;
@property(nonatomic, assign) SEL explanationAction;

@property (nonatomic, retain) NetworkAwareViewController * netController;

@property (nonatomic, retain) UIBarButtonItem * refreshButton;

@end
