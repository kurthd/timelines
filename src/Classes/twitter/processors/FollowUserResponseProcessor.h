//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface FollowUserResponseProcessor : ResponseProcessor
{
    NSString * username;
    BOOL following;
    NSManagedObjectContext * context;
    id delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                  following:(BOOL)isFollowing
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate;
- (id)initWithUsername:(NSString *)aUsername
             following:(BOOL)isFollowing
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
