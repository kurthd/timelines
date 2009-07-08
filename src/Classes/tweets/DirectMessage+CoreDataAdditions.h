//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessage.h"

@interface DirectMessage (CoreDataAdditions)

+ (id)directMessageWithId:(NSString *)anIdentifier
                  context:(NSManagedObjectContext *)context;

@end
