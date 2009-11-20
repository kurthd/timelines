//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UserOrDirectMessage21To23EntityMigrationPolicy.h"

@implementation UserOrDirectMessage21To23EntityMigrationPolicy

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping
                   manager:(NSMigrationManager *)manager
                     error:(NSError **)error
{
    BOOL begin = [super beginEntityMapping:mapping manager:manager error:error];
    if (begin)
        attributesToMigrate =
        [[NSMutableSet alloc] initWithObjects:@"identifier", nil];

    return begin;
}

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)source
                                      entityMapping:(NSEntityMapping *)mapping
                                            manager:(NSMigrationManager *)mgr
                                              error:(NSError **)error
{
    NSManagedObjectContext * destContext = [mgr destinationContext];
    NSString * destEntityName = [mapping destinationEntityName];
    NSManagedObject * dest =
        [NSEntityDescription insertNewObjectForEntityForName:destEntityName
                                      inManagedObjectContext:destContext];

    NSEntityDescription * desc = [source entity];
    for (NSString * attributeName in [[desc attributesByName] allKeys]) {
        id oldVal = [source valueForKey:attributeName];
        BOOL needsConverting =
            oldVal && [attributesToMigrate containsObject:attributeName];

        if (needsConverting) {
            if ([oldVal isKindOfClass:[NSString class]]) {
                // convert the string to an NSNumber
                long long val = [oldVal longLongValue];
                NSNumber * newVal = [NSNumber numberWithLongLong:val];

                [dest setValue:newVal forKey:attributeName];
            }
        }
        else {
            id val = [source valueForKey:attributeName];
            [dest setValue:val forKey:attributeName];
        }
    }

    [mgr associateSourceInstance:source
         withDestinationInstance:dest
                forEntityMapping:mapping];

    return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    if (attributesToMigrate) {
        [attributesToMigrate release];
        attributesToMigrate = nil;
    }
    return [super endEntityMapping:mapping manager:manager error:error];
}

@end