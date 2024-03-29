//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetworkAwareViewControllerDelegate

@optional

- (void)networkAwareViewWillAppear;
- (void)networkAwareViewWillDisappear;
- (void)viewWillRotateToOrientation:(UIInterfaceOrientation)orientation;

@end
