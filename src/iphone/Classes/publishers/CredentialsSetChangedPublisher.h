//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractUpdatePublisher.h"

@interface CredentialsSetChangedPublisher : AbstractUpdatePublisher
{
    id listener;
    SEL action;
}

//
// The selector provided should have the same arguments as:
//   - (void)credentialsChanged:(TwitterCredentials *)credentials;
//
+ (id)publisherWithListener:(id)aListener action:(SEL)anAction;
- (id)initWithListener:(id)aListener action:(SEL)anAction;

@end
