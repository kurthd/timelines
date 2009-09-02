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

+ (id)findFirst:(NSManagedObjectContext *)context
{
    return [self findFirst:nil context:context];
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
        [self findAll:predicate sortBy:nil context:context error:error];

    if (results.count == 0)
        return nil;

    return [results objectAtIndex:0];
}

+ (NSArray *)findAll:(NSManagedObjectContext *)context
{
    return [self findAll:nil context:context];
}

+ (NSArray *)findAll:(NSPredicate *)predicate
             context:(NSManagedObjectContext *)context
{
    NSError * error = nil;
    return [self findAll:predicate sortBy:nil context:context error:&error];
}

+ (NSArray *)findAll:(NSPredicate *)predicate
             context:(NSManagedObjectContext *)context
  prefetchedKeyPaths:(NSArray *)prefetchedKeyPaths
{
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity =
        [NSEntityDescription entityForName:[self className]
                    inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:predicate];
    [request setRelationshipKeyPathsForPrefetching:prefetchedKeyPaths];

    NSArray * results = [context executeFetchRequest:request error:NULL];

    [request release];

    return results;
}

+ (NSArray *)findAll:(NSPredicate *)predicate
              sortBy:(NSSortDescriptor *)sorter
             context:(NSManagedObjectContext *)context
{
    NSError * error = nil;
    return
        [self findAll:predicate sortBy:sorter context:context error:&error];
}

+ (NSArray *)findAll:(NSPredicate *)predicate
              sortBy:(NSSortDescriptor *)sorter
             context:(NSManagedObjectContext *)context
               error:(NSError **)error
{
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity =
        [NSEntityDescription entityForName:[self className]
                    inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:predicate];

    NSArray * sorters = sorter ? [NSArray arrayWithObject:sorter] : nil;
    [request setSortDescriptors:sorters];

    NSArray * results = [context executeFetchRequest:request error:error];

    [request release];

    return results;
}

+ (NSUInteger)deleteAll:(NSManagedObjectContext *)context
{
    return [[self class] deleteAll:nil context:context];
}

+ (NSUInteger)deleteAll:(NSPredicate *)predicate
                context:(NSManagedObjectContext *)context;
{
    NSArray * everything = [[self class] findAll:predicate context:context];
    NSUInteger ndeleted = everything.count;

    for (NSManagedObject * thing in everything)
        [context deleteObject:thing];

    return ndeleted;
}

@end
