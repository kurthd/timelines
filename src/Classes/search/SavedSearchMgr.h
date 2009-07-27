//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SavedSearch.h"

@interface SavedSearchMgr : NSObject
{
    NSManagedObjectContext * context;
    NSString * accountName;
}

@property (nonatomic, copy, readonly) NSString * accountName;
@property (nonatomic, retain, readonly) NSManagedObjectContext * context;

- (id)initWithAccountName:(NSString *)accountName
                  context:(NSManagedObjectContext *)context;

- (NSArray *)savedSearches;

- (void)setSavedSearchOrder:(NSArray *)savedSearches;

- (SavedSearch * )addSavedSearch:(NSString *)query;
- (void)removeSavedSearchForQuery:(NSString *)query;

- (BOOL)isSearchSaved:(NSString *)query;

- (void)clear;

@end
