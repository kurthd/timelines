//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "User+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "NSObject+RuntimeAdditions.h"

@implementation User (CoreDataAdditions)

+ (id)findOrCreateWithId:(NSString *)anIdentifier
                 context:(NSManagedObjectContext *)context
{
    User * user = [[self class] userWithId:anIdentifier context:context];
    if (!user) {
        user = [[self class] createInstance:context];
        Avatar * avatar = [Avatar createInstance:context];
        user.avatar = avatar;
    }

    return user;
}

+ (id)userWithId:(NSString *)targetId
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
        NSAssert2(results.count > 1, @"Found %d users with ID: '%@', but there"
                  "should only be 1.", results.count, targetId);
        NSLog(@"Found %d users with ID: '%@', but there should only be 1.",
              results.count, targetId);
    }

    return [results lastObject];
}

@end