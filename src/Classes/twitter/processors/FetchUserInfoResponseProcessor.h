//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface FetchUserInfoResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSManagedObjectContext * context;
    id<TwitterServiceDelegate> delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithUsername:(NSString *)aUsername
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
