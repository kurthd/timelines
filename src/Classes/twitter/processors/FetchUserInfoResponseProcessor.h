//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface FetchUserInfoResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSManagedObjectContext * context;
    id delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate;
- (id)initWithUsername:(NSString *)aUsername
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
