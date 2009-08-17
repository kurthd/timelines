//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface User (CoreDataAdditions)

+ (id)findOrCreateWithId:(NSString *)anIdentifier
                 context:(NSManagedObjectContext *)context;

+ (id)userWithId:(NSString *)anIdentifier
         context:(NSManagedObjectContext *)context;

@end