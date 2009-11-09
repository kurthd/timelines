//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "TwitterServiceDelegate.h"

@interface BlockUserResponseProcessor : ResponseProcessor
{
    NSString * username;
    BOOL blocking;
    id<TwitterServiceDelegate> delegate;
    NSManagedObjectContext * context;
}

+ (id)processorWithUsername:(NSString *)aUsername
                   blocking:(BOOL)blocking
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id<TwitterServiceDelegate>)aDelegate;
- (id)initWithUsername:(NSString *)aTweetId
              blocking:(BOOL)blocking
               context:(NSManagedObjectContext *)aContext
              delegate:(id<TwitterServiceDelegate>)aDelegate;

@end
