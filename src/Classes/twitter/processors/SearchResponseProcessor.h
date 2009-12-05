//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface SearchResponseProcessor : ResponseProcessor
{
    NSString * query;
    NSString * cursor;
    NSNumber * page;
    NSNumber * maxId;
    id<TwitterServiceDelegate> delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithQuery:(NSString *)aQuery
                  cursor:(NSString *)aCursor
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithQuery:(NSString *)aQuery
             cursor:(NSString *)aCursor
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
