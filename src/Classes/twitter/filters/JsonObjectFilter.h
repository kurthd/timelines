//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TwitterCredentials;

@protocol JsonObjectFilter <NSObject>
- (id)existingObjectForJson:(NSDictionary *)object;
@end

@interface CoreDataJsonObjectFilter : NSObject <JsonObjectFilter>
{
    NSManagedObjectContext * context;
}

@property (nonatomic, retain, readonly) NSManagedObjectContext * context;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext;

@end


@interface IdentifierJsonObjectFilter : CoreDataJsonObjectFilter
{
    NSString * entityName;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
                        entityName:(NSString *)name;

@end


@interface UserEntityJsonObjectFilter : IdentifierJsonObjectFilter
{
    TwitterCredentials * credentials;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
                       credentials:(TwitterCredentials *)credentials
                        entityName:(NSString *)name;

@end

