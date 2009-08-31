//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface DeleteDirectMessageResponseProcessor : ResponseProcessor
{
    NSString * directMessageId;
    id delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithDirectMessageId:(NSString *)aDirectMessageId
                           context:(NSManagedObjectContext *)aContext
                          delegate:(id)aDelegate;
- (id)initWithDirectMessageId:(NSString *)aDirectMessageId
                      context:(NSManagedObjectContext *)aContext
                     delegate:(id)aDelegate;

@end
