//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ResponseProcessor.h"
#import "NSError+InstantiationAdditions.h"

@implementation ResponseProcessor

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Initialization

- (id)init
{
    return (self = [super init]);
}

#pragma mark Processing responses

- (void)process:(id)response
{
    [self processResponse:response];
}

- (void)processError:(NSError *)error
{
    [self processErrorResponse:error];
}

#pragma mark Protected interface implemented by subclasses

- (void)processResponse:(id)response
{
    NSAssert(NO, @"This method must be implemented by subclasses.");
}

- (void)processErrorResponse:(NSError *)error
{
    NSAssert(NO, @"This method must be implemented by subclasses.");
}

#pragma mark Helper methods provided to subclasses

- (BOOL)invokeSelector:(SEL)selector withTarget:(id)target
    args:(id)firstArg, ...
{
    if ([target respondsToSelector:selector]) {
        NSMethodSignature * sig = [target methodSignatureForSelector:selector];
        NSInvocation * inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:target];
        [inv setSelector:selector];

        va_list args;
        va_start(args, firstArg);
        NSInteger argIdx = 2;

        for (id arg = firstArg; arg != nil; arg = va_arg(args, id), ++argIdx)
            [inv setArgument:&arg atIndex:argIdx];

        va_end(args);

        [inv invoke];

        return YES;
    }

    return NO;
}

@end
