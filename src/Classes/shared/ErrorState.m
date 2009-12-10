//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ErrorState.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface ErrorState ()

@property (nonatomic, retain) id currentTarget;
@property (nonatomic, assign) SEL currentAction;
@property (nonatomic, readonly) UIAlertView * retryAlertView;

@end

@implementation ErrorState

@synthesize currentAction, currentTarget, failedState;

static ErrorState * gInstance = NULL;

+ (ErrorState *)instance
{
    @synchronized (self) {
        if (gInstance == NULL)
            gInstance = [[ErrorState alloc] init];
    }

    return gInstance;
}

- (void)dealloc
{
    [retryAlertView release];
    [super dealloc];
}

#pragma mark UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self exitErrorState];
        [self.currentTarget performSelector:self.currentAction];
    }
}

#pragma mark ErrorState implementation

- (void)exitErrorState
{
    failedState = NO;
}

- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error
{
    if (!failedState) {
        failedState = YES;
        NSLog(@"Displaying error with title: %@, error:%@", title, error);
        NSString * message = error.localizedDescription;
        UIAlertView * alertView =
            [UIAlertView simpleAlertViewWithTitle:title message:message];
        [alertView show];
    } else
        NSLog(@"Not displaying error with title: %@, error:%@", title, error);
}

- (void)displayErrorWithTitle:(NSString *)title
{
    [self displayErrorWithTitle:title error:nil];
}

- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error
    retryTarget:(id)target retryAction:(SEL)action
{
    if (!failedState) {
        failedState = YES;
        NSLog(@"Displaying error with title: %@, error:%@", title, error);

        self.currentTarget = target;
        self.currentAction = action;
        self.retryAlertView.title = title;
        self.retryAlertView.message = error.localizedDescription;

        [self.retryAlertView show];
    } else
        NSLog(@"Not displaying error with title: %@, error:%@", title, error);
}

- (UIAlertView *)retryAlertView
{
    if (!retryAlertView) {
        NSString * cancelButtonTitle =
            NSLocalizedString(@"alert.dismiss", @"");
        NSString * retryButtonTitle =
            NSLocalizedString(@"alert.retry", @"");

        retryAlertView =
            [[UIAlertView alloc]
            initWithTitle:nil message:nil delegate:nil
            cancelButtonTitle:cancelButtonTitle
            otherButtonTitles:retryButtonTitle, nil];
        retryAlertView.delegate = self;
    }

    return retryAlertView;
}

@end
