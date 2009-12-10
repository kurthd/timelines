//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErrorState : NSObject <UIAlertViewDelegate>
{
    BOOL failedState;

    // assumes one error handled at a time
    id currentTarget;
    SEL currentAction;

    UIAlertView * retryAlertView;
}

@property (nonatomic, readonly) BOOL failedState;

+ (ErrorState *)instance;

- (void)exitErrorState;
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error;
- (void)displayErrorWithTitle:(NSString *)title;
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error
    retryTarget:(id)target retryAction:(SEL)action;

@end
