//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface BlockUserResponseProcessor : ResponseProcessor
{
    NSString * username;
    BOOL blocking;
    id delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithUsername:(NSString *)aUsername
                   blocking:(BOOL)blocking
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id)aDelegate;
- (id)initWithUsername:(NSString *)aTweetId
              blocking:(BOOL)blocking
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
