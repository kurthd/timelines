//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterList.h"

@interface TwitterList (CoreDataAdditions)

+ (id)findOrCreateWithId:(id)anId context:(NSManagedObjectContext *)context;

@end