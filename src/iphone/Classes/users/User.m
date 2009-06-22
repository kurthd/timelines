// 
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "User.h"
#import "Tweet.h"
#import "NSObject+RuntimeAdditions.h"

@implementation User 

@dynamic username;
@dynamic location;
@dynamic following;
@dynamic bio;
@dynamic webpage;
@dynamic followers;
@dynamic created;
@dynamic profileImageUrl;
@dynamic identifier;
@dynamic name;
@dynamic tweets;

+ (id)createInstance:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self className]
                                         inManagedObjectContext:context];
}

+ (id)userWithId:(NSString *)targetId
         context:(NSManagedObjectContext *)context
{
    NSPredicate * predicate = 
        [NSPredicate predicateWithFormat:@"identifier == %@", targetId];

    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity =
        [NSEntityDescription entityForName:[self className]
                    inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:predicate];
    [request setSortDescriptors:nil];

    NSError * error;
    NSArray * results = [context executeFetchRequest:request error:&error];
    if (results == nil)
        NSLog(@"Error finding '%@' objects: '%@'.", [self className], error);

    if (results.count > 1) {
        NSAssert2(results.count > 1, @"Found %d users with ID: '%@', but there"
            "should only be 1.", results.count, targetId);
        NSLog(@"Found %d users with ID: '%@', but there should only be 1.",
              results.count, targetId);
    }

    [request release];

    return [results lastObject];
}

@end