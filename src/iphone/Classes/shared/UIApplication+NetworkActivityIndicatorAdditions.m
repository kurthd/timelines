//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UIApplication+NetworkActivityIndicatorAdditions.h"

static NSInteger networkActivityCount;

@implementation UIApplication (NetworkActivityIndicatorAdditions)

- (void)networkActivityIsStarting
{
    if (networkActivityCount++ == 0)
        self.networkActivityIndicatorVisible = YES;
}

- (void)networkActivityDidFinish
{
    // decrement before calling 'min' in case min is a macro, which would cause
    // the value to be decremented twice
    --networkActivityCount;

    // don't go below zero to prevent display bugs
    networkActivityCount = networkActivityCount < 0 ? 0 : networkActivityCount;
    if (networkActivityCount == 0)
        self.networkActivityIndicatorVisible = NO;
}

@end
