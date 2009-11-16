//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DecodeHtmlTweetTextEntityMigrationPolicy.h"
#import "TwitbitShared.h"

@implementation DecodeHtmlTweetTextEntityMigrationPolicy

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
        id val = [source valueForKey:attributeName];

        if ([attributeName isEqualToString:@"text"]) {
            id decoded = [val stringByDecodingHtmlEntities];
            [dest setValue:decoded forKey:@"decodedText"];
        }

        [dest setValue:val forKey:attributeName];
    }

    [mgr associateSourceInstance:source
         withDestinationInstance:dest
                forEntityMapping:mapping];

    return YES;
}

@end