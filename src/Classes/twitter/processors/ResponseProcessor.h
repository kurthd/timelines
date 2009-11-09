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

- (BOOL)processResponse:(id)response;
- (BOOL)processErrorResponse:(NSError *)error;

@end
