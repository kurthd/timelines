//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitbitObjectBuilder.h"

@interface TwitbitObjectBuilder ()
@property (nonatomic, retain) id<JsonObjectFilter> filter;
@property (nonatomic, retain) id<JsonObjectTransformer> transformer;
@property (nonatomic, retain) id<TwitbitObjectCreator> creator;
@property (nonatomic, copy) NSArray * existingObjects;
@property (nonatomic, retain) NSMutableArray * newObjects;

- (NSDictionary *)extractExistingObjects:(NSArray *)jsonObjects;
@end

@implementation TwitbitObjectBuilder

@synthesize delegate, filter, transformer, creator, existingObjects, newObjects;

- (void)dealloc
{
    self.delegate = nil;
    self.filter = nil;
    self.transformer = nil;
    self.creator = nil;
    self.existingObjects = nil;
    self.newObjects = nil;

    [super dealloc];
}

- (id)initWithFilter:(id<JsonObjectFilter>)aFilter
         transformer:(id<JsonObjectTransformer>)aTransformer
             creator:(id<TwitbitObjectCreator>)aCreator
{
    if (self = [super init]) {
        self.filter = aFilter;
        self.transformer = aTransformer;
        self.creator = aCreator;
    }

    return self;
}

- (void)buildObjectsFromJsonObjects:(NSArray *)jsonStatuses
{
    NSDictionary * d = [self extractExistingObjects:jsonStatuses];

    self.existingObjects = [d objectForKey:@"twitbit-objects"];
    NSArray * existingJsonObjects = [d objectForKey:@"json-objects"];

    self.newObjects = [[jsonStatuses mutableCopy] autorelease];
    [newObjects removeObjectsInArray:existingJsonObjects];

    // build temporary objects for assembling asynchronously
    SEL sel = @selector(buildObjectsInBackground:);
    [self performSelectorInBackground:sel withObject:newObjects];
}

#pragma mark Private implementation

- (NSArray *)transformObjects:(NSArray *)objects
{
    NSMutableArray * transformedObjects =
        [NSMutableArray arrayWithCapacity:[objects count]];
    for (NSDictionary * object in objects) {
        NSDictionary * transformedObject = [transformer transformObject:object];
        [transformedObjects addObject:transformedObject];
    }

    return transformedObjects;
}

- (void)buildNewObjects:(NSArray *)jsonObjects
{
    NSUInteger capacity = [jsonObjects count];
    NSMutableArray * objects = [NSMutableArray arrayWithCapacity:capacity];

    for (NSDictionary * jsonObject in jsonObjects) {
        id object = [creator createObjectFromJson:jsonObject];
        if (object)
            [objects addObject:object];
    }

    // merge the new objects with the old objects
    [objects addObjectsFromArray:self.existingObjects];

    [self.delegate objectBuilder:self didBuildObjects:objects];
}

- (void)buildObjectsInBackground:(NSArray *)objects
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSArray * transformedObjects = [self transformObjects:objects];

    // switch back to the main thread to create the final objects; wait
    // until done so the autorelease pool doesn't drain until object
    // creation is finished
    SEL sel = @selector(buildNewObjects:);
    [self performSelectorOnMainThread:sel
                           withObject:transformedObjects
                        waitUntilDone:YES];

    [pool release];
}

- (NSDictionary *)extractExistingObjects:(NSArray *)jsonObjects
{
    NSUInteger capacity = [jsonObjects count];
    NSMutableArray * existingJson = [NSMutableArray arrayWithCapacity:capacity];
    NSMutableArray * existing = [NSMutableArray arrayWithCapacity:capacity];

    for (id jsonObject in jsonObjects) {
        id existingObject = [filter existingObjectForJson:jsonObject];
        if (existingObject) {
            [existingJson addObject:jsonObject];
            [existing addObject:existingObject];
        }
    }

    return
        [NSDictionary dictionaryWithObjectsAndKeys:
        existingJson, @"json-objects",
        existing, @"twitbit-objects",
        nil];
}

@end
