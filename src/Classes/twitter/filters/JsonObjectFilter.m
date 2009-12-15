//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "JsonObjectFilter.h"
#import "TwitbitShared.h"

@interface CoreDataJsonObjectFilter ()
@property (nonatomic, retain) NSManagedObjectContext * context;
@end

@implementation CoreDataJsonObjectFilter

@synthesize context;

- (void)dealloc
{
    self.context = nil;
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init])
        self.context = aContext;

    return self;
}

#pragma mark JsonObjectFilter implementation

- (id)existingObjectForJson:(NSDictionary *)object
{
    return nil;
}

@end




@implementation IdentifierJsonObjectFilter : CoreDataJsonObjectFilter
{
    NSString * entityName;
}

- (void)dealloc
{
    [entityName release];
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
                        entityName:(NSString *)name
{
    if (self = [super initWithManagedObjectContext:aContext])
        entityName = [name copy];

    return self;
}

- (NSPredicate *)predicateForIdentifier:(id)identifier
{
    return [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
}

- (id)existingObjectForJson:(NSDictionary *)object;
{
    NSNumber * tweetId = [[object objectForKey:@"id"] twitterIdentifierValue];

    NSPredicate * predicate = [self predicateForIdentifier:tweetId];

    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity =
        [NSEntityDescription entityForName:entityName
                    inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:predicate];

    NSError * error = nil;
    NSArray * results = [context executeFetchRequest:request error:&error];

    [request release];

    if (error == nil && [results count] == 1)
        return [results objectAtIndex:0];
    return nil;
}

@end




@implementation UserEntityJsonObjectFilter

- (void)dealloc
{
    [credentials release];
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
                       credentials:(TwitterCredentials *)someCredentials
                        entityName:(NSString *)name
{
    
    if (self = [super initWithManagedObjectContext:aContext entityName:name])
        credentials = [someCredentials retain];

    return self;
}

- (NSPredicate *)predicateForIdentifier:(id)identifier
{
    return
        [NSPredicate predicateWithFormat:
        @"identifier == %@ AND credentials == %@",
        identifier, credentials];
}

@end

