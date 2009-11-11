//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface FollowUserResponseProcessor : ResponseProcessor
{
    NSString * username;
    BOOL following;
    NSManagedObjectContext * context;
    id<TwitterServiceDelegate> delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                  following:(BOOL)isFollowing
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithUsername:(NSString *)aUsername
             following:(BOOL)isFollowing
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
