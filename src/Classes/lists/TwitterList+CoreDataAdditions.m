//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitterList+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@implementation TwitterList (CoreDataAdditions)

+ (id)findOrCreateWithId:(id)anId context:(NSManagedObjectContext *)context
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"identifier == %@", anId];
    id list = [TwitterList findFirst:predicate context:context];
    if (!list)
        list = [TwitterList createInstance:context];

    return list;
}

@end