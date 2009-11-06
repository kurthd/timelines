//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"

@interface SendTweetResponseProcessor : ResponseProcessor
{
    NSString * text;
    NSNumber * referenceId;
    TwitterCredentials * credentials;
    id delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweet:(NSString *)someText
             referenceId:(NSNumber *)aReferenceId
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate;
- (id)initWithTweet:(NSString *)someText
        referenceId:(NSNumber *)aReferenceId
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate;

@end
