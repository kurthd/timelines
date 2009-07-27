//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "RecentSearchMgr.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface RecentSearchMgr ()

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, copy) NSString * accountName;

- (NSString *)normalizeQuery:(NSString *)query;

@end

@implementation RecentSearchMgr

@synthesize context, accountName, maximumRecentSearches;

- (void)dealloc
{
    self.accountName = nil;
    self.context = nil;
    [super dealloc];
}

- (id)initWithAccountName:(NSString *)anAccountName
                  context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.accountName = anAccountName;
        self.context = aContext;
        self.maximumRecentSearches =
            [[self class] defaultMaximumRecentSearches];
    }

    return self;
}

- (NSArray *)recentSearches
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"accountName == %@", accountName];
    NSSortDescriptor * sorter =
        [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];

    NSArray * recentSearches =
        [RecentSearch findAll:predicate sortBy:sorter context:self.context];

    [sorter release];

    return recentSearches;
}

- (RecentSearch * )addRecentSearch:(NSString *)query
{
    query = [self normalizeQuery:query];

    NSMutableArray * recentSearches = [[self recentSearches] mutableCopy];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"accountName == %@ && query == %@", 
        self.accountName, query];
    RecentSearch * recentSearch = [RecentSearch findFirst:predicate
                                                  context:context];
    if (!recentSearch) {
        recentSearch = [RecentSearch createInstance:context];
        recentSearch.query = query;
        recentSearch.accountName = self.accountName;
    } else
        for (NSInteger i = 0, count = recentSearches.count; i < count; ++i) {
            RecentSearch * rs = [recentSearches objectAtIndex:i];
            if ([rs.query isEqualToString:query]) {
                [recentSearches removeObjectAtIndex:i];
                break;
            }
        }

    recentSearch.timestamp = [NSDate date];

    [recentSearches insertObject:recentSearch atIndex:0];
    NSInteger overflow = recentSearches.count - self.maximumRecentSearches;
    if (overflow > 0) {
        // physically delete the recent search objects
        for (NSInteger i = 0; i < overflow; ++i) {
            RecentSearch * poppedSearch =
                [recentSearches objectAtIndex:i + self.maximumRecentSearches];
            [self.context deleteObject:poppedSearch];
        }
    }

    [self.context save:NULL];

    return recentSearch;
}

- (void)clear
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"accountName == %@", accountName];
    [RecentSearch deleteAll:predicate context:self.context];

    [context save:NULL];
}

+ (NSUInteger)defaultMaximumRecentSearches
{
    return 20;
}

#pragma mark Private methods

- (NSString *)normalizeQuery:(NSString *)query
{
    return [query lowercaseString];
}

@end
