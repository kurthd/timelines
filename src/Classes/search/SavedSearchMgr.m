//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SavedSearchMgr.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface SavedSearchMgr ()

@property (nonatomic, retain) NSManagedObjectContext * context;

- (NSString *)normalizeQuery:(NSString *)query;

@end

@implementation SavedSearchMgr

@synthesize context, accountName;

- (void)dealloc
{
    self.context = nil;
    self.accountName = nil;

    [super dealloc];
}

- (id)initWithAccountName:(NSString *)anAccountName
                  context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.accountName = anAccountName;
        self.context = aContext;
    }

    return self;
}

- (NSArray *)savedSearches
{
    NSError * error = nil;
    NSPredicate * predicate =
        [NSPredicate
        predicateWithFormat:@"accountName == %@", self.accountName];
    NSSortDescriptor * sorter =
        [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];

    return [SavedSearch findAll:predicate
                         sortBy:sorter
                        context:self.context
                          error:&error];
}

- (void)setSavedSearchOrder:(NSArray *)savedSearches
{
    // these are just SavedSearch instances, so just set them and save
    for (NSUInteger i = 0, count = savedSearches.count; i < count; ++i) {
        SavedSearch * search = [savedSearches objectAtIndex:i];
        search.displayOrder = [NSNumber numberWithInteger:i];
    }

    [self.context save:NULL];
}

- (SavedSearch * )addSavedSearch:(NSString *)query
{
    query = [self normalizeQuery:query];

    NSAssert(![self isSearchSaved:query],
        @"Adding a query that is already bookmarked");

    SavedSearch * bookmark = [SavedSearch createInstance:context];
    bookmark.query = query;
    bookmark.accountName = accountName;
    bookmark.displayOrder =
        [NSNumber numberWithInteger:[self savedSearches].count];

    [self.context save:NULL];

    return bookmark;
}

- (void)removeSavedSearchForQuery:(NSString *)query
{
    query = [self normalizeQuery:query];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"accountName == %@ && query == %@",
        self.accountName, query];
    SavedSearch * bookmark = [SavedSearch findFirst:predicate
                                            context:context];
    if (bookmark)
        [self.context deleteObject:bookmark];
}

- (BOOL)isSearchSaved:(NSString *)query
{
    query = [self normalizeQuery:query];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"accountName == %@ && query == %@",
        self.accountName, query];

    return !![SavedSearch findFirst:predicate context:self.context];
}

- (void)clear
{
    NSPredicate * predicate =
        [NSPredicate
        predicateWithFormat:@"accountName == %@", self.accountName];
    [SavedSearch deleteAll:predicate context:self.context];

    [context save:NULL];
}

#pragma mark Private methods

- (NSString *)normalizeQuery:(NSString *)query
{
    return [query lowercaseString];
}

@end
