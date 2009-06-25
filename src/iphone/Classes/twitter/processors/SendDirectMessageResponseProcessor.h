//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface SendDirectMessageResponseProcessor : ResponseProcessor
{
    NSString * text;
    NSString * username;
    id delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweet:(NSString *)someText
                username:(NSString *)aUsername
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate;
- (id)initWithTweet:(NSString *)someText
           username:(NSString *)aUsername
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate;

@end
