//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JsonObjectFilter.h"
#import "JsonObjectTransformer.h"
#import "TwitbitObjectCreator.h"

@protocol TwitbitObjectBuilderDelegate;

@interface TwitbitObjectBuilder : NSObject
{
    id<TwitbitObjectBuilderDelegate> delegate;

    id<JsonObjectFilter> filter;
    id<JsonObjectTransformer> transformer;
    id<TwitbitObjectCreator> creator;

    NSArray * existingObjects;
    NSMutableArray * newObjects;
}

@property (nonatomic, assign) id<TwitbitObjectBuilderDelegate> delegate;

- (id)initWithFilter:(id<JsonObjectFilter>)aFilter
         transformer:(id<JsonObjectTransformer>)aTransformer
             creator:(id<TwitbitObjectCreator>)aCreator;

- (void)buildObjectsFromJsonObjects:(NSArray *)jsonStatuses;

@end


@protocol TwitbitObjectBuilderDelegate

- (void)objectBuilder:(TwitbitObjectBuilder *)builder
      didBuildObjects:(NSArray *)objects;

@end

