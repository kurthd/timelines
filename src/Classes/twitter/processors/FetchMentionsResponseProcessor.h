//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"
#import "TwitbitObjectBuilder.h"

@interface FetchMentionsResponseProcessor :
    ResponseProcessor <TwitbitObjectBuilderDelegate>
{
    NSNumber * updateId;
    NSNumber * page;
    NSNumber * count;
    TwitterCredentials * credentials;
    id<TwitterServiceDelegate> delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                credentials:(TwitterCredentials *)someCredentials
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
           credentials:(TwitterCredentials *)someCredentials
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
