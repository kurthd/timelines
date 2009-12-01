//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ContactCache.h"

@interface ContactCachePersistenceStore : NSObject
{
    ContactCache * contactCache;
}

- (id)initWithContactCache:(ContactCache *)contactCache;

- (void)load;
- (void)save;

@end
