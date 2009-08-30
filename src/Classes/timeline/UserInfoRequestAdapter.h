//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterServiceDelegate.h"
#import "NetworkAwareViewController.h"

@interface UserInfoRequestAdapter : NSObject <TwitterServiceDelegate>
{
    id target;
    // of the form - (void)setUser:(User *)user
    SEL action;
    NetworkAwareViewController * wrapperController;
    id errorHandler;
}

- (id)initWithTarget:(id)target action:(SEL)action
    wrapperController:(NetworkAwareViewController *)wrapperController
    errorHandler:(id)errorHandler;

@end
