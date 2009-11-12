//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface User (CoreDataAdditions)

+ (id)findOrCreateWithId:(NSNumber *)anIdentifier
                 context:(NSManagedObjectContext *)context;

+ (id)userWithId:(NSNumber *)anIdentifier
         context:(NSManagedObjectContext *)context;

+ (id)userWithUsername:(NSString *)username
               context:(NSManagedObjectContext *)context;

@end