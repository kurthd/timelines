//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIState.h"

@interface UIStatePersistenceStore : NSObject

- (UIState *)load;
- (void)save:(UIState *)state;

@end
