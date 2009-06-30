//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface FetchTweetResponseProcessor : ResponseProcessor
{
    NSString * tweetId;
    id delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithTweetId:(NSString *)aTweetId
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id)aDelegate;
- (id)initWithTweetId:(NSString *)aTweetId
              context:(NSManagedObjectContext *)aContext
             delegate:(id)aDelegate;

@end