//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface UserSearchResponseProcessor : ResponseProcessor
{
    NSString * query;
    NSNumber * count;
    NSNumber * page;
    NSManagedObjectContext * context;
    id<TwitterServiceDelegate> delegate;
}

+ (id)processorWithQuery:(NSString *)aQuery
                   count:(NSNumber *)aCount
                    page:(NSNumber *)aPage
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithQuery:(NSString *)aQuery
              count:(NSNumber *)aCount
               page:(NSNumber *)aPage
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
