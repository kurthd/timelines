//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserTwitterList.h"
#import "TwitterCredentials.h"

@interface UserTwitterList (CoreDataAdditions)

+ (id)findOrCreateWithId:(id)anId
             credentials:(TwitterCredentials *)credentials
                 context:(NSManagedObjectContext *)context;

@end