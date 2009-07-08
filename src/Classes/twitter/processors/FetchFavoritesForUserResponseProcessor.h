//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface FetchFavoritesForUserResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSNumber * page;
    id delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithUsername:(NSString *)aUsername
                       page:(NSNumber *)aPage
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate;

- (id)initWithUsername:(NSString *)aUsername
                  page:(NSNumber *)aPage
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
