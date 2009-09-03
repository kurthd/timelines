//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface BlockExistsResponseProcessor : ResponseProcessor
{
    NSString * username;
    id delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithUsername:(NSString *)aUsername
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id)aDelegate;
- (id)initWithUsername:(NSString *)aTweetId
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
