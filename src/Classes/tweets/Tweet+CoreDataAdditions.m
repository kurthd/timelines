//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "Tweet+CoreDataAdditions.h"
#import "NSObject+RuntimeAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@implementation Tweet (CoreDataAdditions)

+ (id)tweetWithId:(NSNumber *)targetId
          context:(NSManagedObjectContext *)context
{
    NSPredicate * predicate = 
    [NSPredicate predicateWithFormat:@"identifier == %@", targetId];

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
