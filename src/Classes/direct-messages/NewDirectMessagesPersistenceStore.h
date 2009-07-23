//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewDirectMessagesState.h"

@interface NewDirectMessagesPersistenceStore : NSObject

- (NewDirectMessagesState *)load;
- (void)save:(NewDirectMessagesState *)state;

@end
