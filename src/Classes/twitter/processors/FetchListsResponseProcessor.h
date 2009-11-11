//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@interface FetchListsResponseProcessor : ResponseProcessor
{
    TwitterCredentials * credentials;
    NSString * cursor;
    id<TwitterServiceDelegate> delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithCredentials:(TwitterCredentials *)someCredentials
                        cursor:(NSString *)aCursor
                       context:(NSManagedObjectContext *)aContext
                      delegate:(id<TwitterServiceDelegate>)aDelegate;

- (id)initWithCredentials:(TwitterCredentials *)someCredentials
                   cursor:(NSString *)aCursor
                  context:(NSManagedObjectContext *)aContext
                 delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
