//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"

@interface SendDirectMessageResponseProcessor : ResponseProcessor
{
    NSString * text;
    NSString * username;
    TwitterCredentials * credentials;
    id delegate;

    NSManagedObjectContext * context;
}

+ (id)processorWithTweet:(NSString *)someText
                username:(NSString *)aUsername
             credentials:(TwitterCredentials *)someCredentials
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate;
- (id)initWithTweet:(NSString *)someText
           username:(NSString *)aUsername
        credentials:(TwitterCredentials *)someCredentials
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate;

@end
