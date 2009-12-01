//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ContactCache.h"

@implementation ContactCache

@synthesize recordIds;

- (void)dealloc
{
    [recordIds release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
        recordIds = [[NSMutableDictionary dictionary] retain];

    return self;
}

#pragma mark ContactCacheReader implementation

- (ABRecordID)recordIdForUser:(NSString *)username
{
    NSLog(@"Retrieving AB record for %@ ", username);
    NSNumber * recordId = [recordIds objectForKey:username];
    NSLog(@"Record id: %@", recordId);
    return recordId ? [recordId intValue] : kABRecordInvalidID;
}

#pragma mark ContactCacheSetter implementation

- (void)setRecordId:(ABRecordID)recordId forUser:(NSString *)username
{
    NSLog(@"Setting AB record %d for username %@ ", recordId, username);
    NSLog(@"RecordIds: %@", recordIds);
    [recordIds setObject:[NSNumber numberWithInteger:recordId] forKey:username];
    NSLog(@"RecordIds: %@", recordIds);
}

@end
