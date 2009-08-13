//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErrorState : NSObject
{
    BOOL failedState;
}

+ (ErrorState *)instance;

- (void)exitErrorState;
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error;
- (void)displayErrorWithTitle:(NSString *)title;

@end
