//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ErrorState.h"
#import "UIAlertView+InstantiationAdditions.h"

@implementation ErrorState

static ErrorState * gInstance = NULL;

+ (ErrorState *)instance
{
    @synchronized(self) {
        if (gInstance == NULL)
            gInstance = [[self alloc] init];
    }

    return(gInstance);
}

- (void)exitErrorState
{
    failedState = NO;
}

- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error
{
    if (!failedState) {
        NSLog(@"Displaying error with title: %@, error:%@", title, error);
        NSString * message = error.localizedDescription;
        UIAlertView * alertView =
            [UIAlertView simpleAlertViewWithTitle:title message:message];
        [alertView show];

        failedState = YES;
    }
}

- (void)displayErrorWithTitle:(NSString *)title
{
    [self displayErrorWithTitle:title error:nil];
}

@end
