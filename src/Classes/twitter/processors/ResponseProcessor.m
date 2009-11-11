//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ResponseProcessor.h"
#import "NSError+InstantiationAdditions.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

@implementation ResponseProcessor

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Initialization

- (id)init
{
    if (self = [super init])
        [[UIApplication sharedApplication] networkActivityIsStarting];

    return self;
}

#pragma mark Processing responses

- (void)process:(id)response
{
    if ([self processResponse:response])
        [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)processError:(NSError *)error
{
    if ([self processErrorResponse:error])
        [[UIApplication sharedApplication] networkActivityDidFinish];
}

#pragma mark Protected interface implemented by subclasses

- (BOOL)processResponse:(id)response
{
    NSAssert(NO, @"This method must be implemented by subclasses.");
    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSAssert(NO, @"This method must be implemented by subclasses.");
    return YES;
}

@end
