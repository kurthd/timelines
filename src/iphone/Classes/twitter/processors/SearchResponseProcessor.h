//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface SearchResponseProcessor : ResponseProcessor
{
    NSString * query;
    NSNumber * page;
    id delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithQuery:(NSString *)aQuery
                    page:(NSNumber *)aPage
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate;
- (id)initWithQuery:(NSString *)aQuery
               page:(NSNumber *)aPage
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate;

@end
