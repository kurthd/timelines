//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <AddressBookUI/ABNewPersonViewController.h>
#import "ContactCachePersistenceStore.h"
#import "PListUtils.h"

@interface ContactCachePersistenceStore (Private)

+ (NSString *)plistName;

@end

@implementation ContactCachePersistenceStore

- (void)dealloc
{
    [contactCache release];
    [super dealloc];
}

- (id)initWithContactCache:(ContactCache *)aContactCache
{
    if (self = [super init])
        contactCache = [aContactCache retain];

    return self;
}

- (void)load
{
    NSDictionary * recordIds =
        [PlistUtils getDictionaryFromPlist:[[self class] plistName]];

    for (NSString * username in [recordIds allKeys]) {
        ABRecordID recordId = [[recordIds objectForKey:username] intValue];
        [contactCache setRecordId:recordId forUser:username];
    }
}

- (void)save
{
    [PlistUtils saveDictionary:contactCache.recordIds
        toPlist:[[self class] plistName]];
}

#pragma mark Static helpers

+ (NSString *)plistName
{
    return @"ContactCache";
}

@end
