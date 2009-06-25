//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface SendTweetResponseProcessor : ResponseProcessor
{
    NSString * text;
    NSString * referenceId;
    id delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweet:(NSString *)someText
             referenceId:(NSString *)aReferenceId
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate;
- (id)initWithTweet:(NSString *)someText
        referenceId:(NSString *)aReferenceId
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate;

@end
