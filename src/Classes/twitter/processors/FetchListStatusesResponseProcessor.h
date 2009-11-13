//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@interface FetchListStatusesResponseProcessor : ResponseProcessor
{
    NSNumber * listId;
    NSString * username;
    NSNumber * updateId;
    NSNumber * page;
    NSNumber * count;
    id<TwitterServiceDelegate> delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithListId:(NSNumber *)aListId
              ownedByUser:(NSString *)aUsername
            sinceUpdateId:(NSNumber *)anUpdateId
                     page:(NSNumber *)aPage
                    count:(NSNumber *)aCount
                  context:(NSManagedObjectContext *)aContext
                 delegate:(id<TwitterServiceDelegate>)aDelegate;

- (id)initWithListId:(NSNumber *)aListId
         ownedByUser:(NSString *)aUsername
       sinceUpdateId:(NSNumber *)anUpdateId
                page:(NSNumber *)aPage
               count:(NSNumber *)aCount
             context:(NSManagedObjectContext *)aContext
            delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
