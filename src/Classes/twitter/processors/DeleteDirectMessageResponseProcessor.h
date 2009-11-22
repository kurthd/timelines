//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface DeleteDirectMessageResponseProcessor : ResponseProcessor
{
    NSNumber * directMessageId;
    id<TwitterServiceDelegate> delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithDirectMessageId:(NSNumber *)aDirectMessageId
                           context:(NSManagedObjectContext *)aContext
                          delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithDirectMessageId:(NSNumber *)aDirectMessageId
                      context:(NSManagedObjectContext *)aContext
                     delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
