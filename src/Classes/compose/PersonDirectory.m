//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PersonDirectory.h"

@interface PersonDirectory ()

@property (nonatomic, copy) NSArray * people;

@end


@implementation PersonDirectory

@synthesize people;

- (void)dealloc
{
    self.people = nil;
    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

- (NSArray *)allPeople
{
    return self.people;
}

@end


@implementation PersonDirectory (PersistenceLoadingAdditions)

- (void)loadAllFromPersistence:(NSManagedObjectContext *)context
                        ofType:(NSString *)className
{
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity =
        [NSEntityDescription
        entityForName:className inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:nil];

    NSArray * results = [context executeFetchRequest:request error:NULL];

    [request release];

    self.people = results;
}

@end
