//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResponseProcessor : NSObject
{
}

#pragma mark Initialization

- (id)init;

#pragma mark Processing responses

- (void)process:(id)response;
- (void)processError:(NSError *)error;

#pragma mark Protected interface implemented by subclasses

- (void)processResponse:(id)response;
- (void)processErrorResponse:(NSError *)error;

#pragma mark Helper methods provided to subclasses

- (BOOL)invokeSelector:(SEL)selector withTarget:(id)target
    args:(id)firstArg, ... NS_REQUIRES_NIL_TERMINATION;

@end
