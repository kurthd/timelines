//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UserTweet+CoreDataAdditions.h"
#import "NSObject+RuntimeAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@implementation UserTweet (CoreDataAdditions)

+ (id)tweetWithId:(NSNumber *)targetId
      credentials:(TwitterCredentials *)credentials
          context:(NSManagedObjectContext *)context
{
    NSPredicate * predicate = 
        [NSPredicate predicateWithFormat:
        @"identifier == %@ && credentials.username == %@", targetId,
        credentials.username];

    NSError * error;
    NSArray * results =
        [self findAll:predicate sortBy:nil context:context error:&error];
    if (results == nil)
        NSLog(@"Error finding '%@' objects: '%@'.", [self className], error);

    if (results.count > 1) {
        NSAssert2(results.count > 1, @"Found %d tweets with ID: '%@', but there"
            "should only be 1.", results.count, targetId);
        NSLog(@"Found %d tweets with ID: '%@', but there should only be 1.",
            results.count, targetId);
    }

    return [results lastObject];
}

@end
