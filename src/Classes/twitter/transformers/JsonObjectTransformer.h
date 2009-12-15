//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol JsonObjectTransformer <NSObject>
- (id)transformObject:(NSDictionary *)object;
@end



@interface SimpleJsonObjectTransformer : NSObject <JsonObjectTransformer>
{
    id<JsonObjectTransformer> userTransformer;
}

+ (id)instance;
- (id)initWithUserTransformer:(id<JsonObjectTransformer>)aUserTransformer;

@end


@interface UserJsonObjectTransformer : NSObject <JsonObjectTransformer>
{
}

+ (id)instance;

@end


@interface DirectMessageJsonObjectTransformer : NSObject <JsonObjectTransformer>
{
    id<JsonObjectTransformer> userTransformer;
}

+ (id)instance;
- (id)initWithUserTransformer:(id<JsonObjectTransformer>)aUserTransformer;

@end

