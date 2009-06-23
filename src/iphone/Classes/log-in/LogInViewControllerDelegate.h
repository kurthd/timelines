//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LogInViewControllerDelegate

- (void)userDidProvideUsername:(NSString *)username
                      password:(NSString *)password;
- (void)userDidCancel;

- (BOOL)userCanCancel;

@end
