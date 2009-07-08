//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"

@interface CheckCredentialsResponseProcessor : ResponseProcessor
{
    TwitterCredentials * credentials;
    id delegate;
}

+ (id)processorWithCredentials:(TwitterCredentials *)someCredentials
                      delegate:(id)aDelegate;
- (id)initWithCredentials:(TwitterCredentials *)someCredentials
                 delegate:(id)aDelegate;

@end
