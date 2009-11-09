//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessors.h"
#import "TwitterServiceDelegate.h"

@interface QueryIsFollowingResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSString * followee;
    NSManagedObjectContext * context;
    id<TwitterServiceDelegate> delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                   followee:(NSString *)aFollowee
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate;

- (id)initWithUsername:(NSString *)aUsername
              followee:(NSString *)aFollowee
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
