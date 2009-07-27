//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecentSearch.h"

@interface RecentSearchMgr : NSObject
{
    NSManagedObjectContext * context;
    NSString * accountName;
    NSUInteger maximumRecentSearches;
}

@property (nonatomic, copy, readonly) NSString * accountName;
@property (nonatomic, retain, readonly) NSManagedObjectContext * context;
@property (nonatomic, assign) NSUInteger maximumRecentSearches;

- (id)initWithAccountName:(NSString *)accountName
                  context:(NSManagedObjectContext *)context;

- (NSArray *)recentSearches;

- (RecentSearch * )addRecentSearch:(NSString *)searchTerms;
- (void)clear;

+ (NSUInteger)defaultMaximumRecentSearches;

@end