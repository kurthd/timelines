//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PersonDirectory : NSObject
{
    NSArray * people;
}

- (id)init;

- (NSArray *)allPeople;

@end


@interface PersonDirectory (PersistenceLoadingAdditions)

- (void)loadAllFromPersistence:(NSManagedObjectContext *)context
                        ofType:(NSString *)className;

@end
