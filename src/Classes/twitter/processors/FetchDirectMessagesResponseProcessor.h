//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@interface FetchDirectMessagesResponseProcessor : ResponseProcessor
{
    NSNumber * updateId;
    NSNumber * page;
    BOOL sent;
    NSNumber * count;
    TwitterCredentials * credentials;
    id<TwitterServiceDelegate> delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                       sent:(BOOL)isSent
                credentials:(TwitterCredentials *)someCredentials
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
                  sent:(BOOL)isSent
           credentials:(TwitterCredentials *)someCredentials
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
