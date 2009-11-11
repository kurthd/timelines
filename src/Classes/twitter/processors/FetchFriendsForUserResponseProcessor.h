//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface FetchFriendsForUserResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSString * cursor;
    NSManagedObjectContext * context;
    id<TwitterServiceDelegate> delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                     cursor:(NSString *)aCursor
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithUsername:(NSString *)aUsername
                cursor:(NSString *)aCursor
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
