//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"

@interface FetchFriendsForUserResponseProcessor : ResponseProcessor
{
    NSString * username;
    NSString * cursor;
    NSManagedObjectContext * context;
    id delegate;
}

+ (id)processorWithUsername:(NSString *)aUsername
                     cursor:(NSString *)aCursor
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate;
- (id)initWithUsername:(NSString *)aUsername
                cursor:(NSString *)aCursor
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate;

@end
