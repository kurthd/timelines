//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (TediousCodeAdditions)

+ (id)createInstance:(NSManagedObjectContext *)context;

+ (id)findFirst:(NSManagedObjectContext *)context;
+ (id)findFirst:(NSPredicate *)predicate
        context:(NSManagedObjectContext *)context;
+ (id)findFirst:(NSPredicate *)predicate
        context:(NSManagedObjectContext *)context
          error:(NSError **)error;

+ (NSArray *)findAll:(NSManagedObjectContext *)context;
+ (NSArray *)findAll:(NSPredicate *)predicate
             context:(NSManagedObjectContext *)context;
+ (NSArray *)findAll:(NSPredicate *)predicate
             context:(NSManagedObjectContext *)context
  prefetchedKeyPaths:(NSArray *)prefetchedKeyPaths;
+ (NSArray *)findAll:(NSPredicate *)predicate
              sortBy:(NSSortDescriptor *)sorter
             context:(NSManagedObjectContext *)context;
+ (NSArray *)findAll:(NSPredicate *)predicate
              sortBy:(NSSortDescriptor *)sorter
             context:(NSManagedObjectContext *)context
               error:(NSError **)error;

+ (NSUInteger)deleteAll:(NSManagedObjectContext *)context;
+ (NSUInteger)deleteAll:(NSPredicate *)predicate
                context:(NSManagedObjectContext *)context;

@end
