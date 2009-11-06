//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserTweet.h"
#import "TwitterCredentials.h"

@interface UserTweet (CoreDataAdditions)

+ (id)tweetWithId:(NSNumber *)anIdentifier
      credentials:(TwitterCredentials *)credentials
          context:(NSManagedObjectContext *)context;

@end