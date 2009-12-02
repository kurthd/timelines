//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@interface SendRetweetResponseProcessor : ResponseProcessor
{
    NSNumber * tweetId;
    TwitterCredentials * credentials;
    id<TwitterServiceDelegate> delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweetId:(NSNumber *)aTweetId
               credentials:(TwitterCredentials *)someCredentials
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id<TwitterServiceDelegate>)aDelegate;

- (id)initWithTweetId:(NSNumber *)aTweetId
          credentials:(TwitterCredentials *)someCredentials
              context:(NSManagedObjectContext *)aContext
             delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
