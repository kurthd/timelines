//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UserTwitterList+CoreDataAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@implementation UserTwitterList (CoreDataAdditions)

+ (id)findOrCreateWithId:(id)anId
             credentials:(TwitterCredentials *)credentials
                 context:(NSManagedObjectContext *)context
{
    NSPredicate * predicate =
        [NSPredicate
         predicateWithFormat:@"identifier == %@ AND credentials.username == %@",
         anId, credentials.username];
    id list = [UserTwitterList findFirst:predicate context:context];
    if (!list)
        list = [UserTwitterList createInstance:context];

    return list;
}

@end