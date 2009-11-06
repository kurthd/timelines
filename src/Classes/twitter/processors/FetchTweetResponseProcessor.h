//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface FetchTweetResponseProcessor : ResponseProcessor
{
    NSNumber * tweetId;
    id delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithTweetId:(NSNumber *)aTweetId
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id)aDelegate;
- (id)initWithTweetId:(NSNumber *)aTweetId
              context:(NSManagedObjectContext *)aContext
             delegate:(id)aDelegate;

@end
