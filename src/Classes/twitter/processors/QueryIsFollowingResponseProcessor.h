//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessors.h"

@interface QueryIsFollowingResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSString * followee;
    NSManagedObjectContext * context;
    id delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                   followee:(NSString *)aFollowee
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate;

- (id)initWithUsername:(NSString *)aUsername
              followee:(NSString *)aFollowee
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
