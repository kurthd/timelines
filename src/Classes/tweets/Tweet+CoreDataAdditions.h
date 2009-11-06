//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tweet.h"

@interface Tweet (CoreDataAdditions)

+ (id)tweetWithId:(NSNumber *)anIdentifier
          context:(NSManagedObjectContext *)context;

@end