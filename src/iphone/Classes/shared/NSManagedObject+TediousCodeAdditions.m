//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSManagedObject+TediousCodeAdditions.h"
#import "NSObject+RuntimeAdditions.h"

@implementation NSManagedObject (TediousCodeAdditions)

+ (id)createInstance:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self className]
                                         inManagedObjectContext:context];
}

+ (id)findFirst:(NSPredicate *)predicate
        context:(NSManagedObjectContext *)context
{
    NSError * error;
    return [self findFirst:predicate context:context error:&error];
}

+ (id)findFirst:(NSPredicate *)predicate
        context:(NSManagedObjectContext *)context
          error:(NSError **)error
{
    NSArray * results =
        [self findAll:predicate context:context error:error];

    return [results objectAtIndex:0];
}

+ (id)findAll:(NSPredicate *)predicate
      context:(NSManagedObjectContext *)context
{
    NSError * error;
    return [self findAll:predicate context:context error:&error];
}

+ (id)findAll:(NSPredicate *)predicate
      context:(NSManagedObjectContext *)context
        error:(NSError **)error
{
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity =
        [NSEntityDescription entityForName:[self className]
                    inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:predicate];
    [request setSortDescriptors:nil];

    NSArray * results = [context executeFetchRequest:request error:error];

    [request release];

    return results;
}

@end
