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

+ (id)findAll:(NSManagedObjectContext *)context;
+ (id)findAll:(NSPredicate *)predicate
      context:(NSManagedObjectContext *)context;
+ (id)findAll:(NSPredicate *)predicate
      context:(NSManagedObjectContext *)context
        error:(NSError **)error;

@end
