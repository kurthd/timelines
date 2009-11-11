//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@interface CheckCredentialsResponseProcessor : ResponseProcessor
{
    TwitterCredentials * credentials;
    id<TwitterServiceDelegate> delegate;
}

+ (id)processorWithCredentials:(TwitterCredentials *)someCredentials
                      delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithCredentials:(TwitterCredentials *)someCredentials
                 delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
