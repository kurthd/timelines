//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSArray+IterationAdditions.h"

@implementation NSArray (IterationAdditions)

- (NSArray *)arrayByTransformingObjectsUsingSelector:(SEL)sel
{
    NSMutableArray * transformedArray =
        [NSMutableArray arrayWithCapacity:self.count];

    for (id object in self)
        [transformedArray addObject:[object performSelector:sel]];

    return transformedArray;
}

- (NSArray *)arrayByFilteringObjectsUsingSelector:(SEL)sel
{
    NSMutableArray * filteredArray =
        [NSMutableArray arrayWithCapacity:self.count];

    for (id candidate in self)
        if ([candidate performSelector:sel])
            [filteredArray addObject:candidate];

    return filteredArray;
}

- (NSArray *)arrayByFilteringObjectsUsingSelector:(SEL)sel withObject:(id)obj
{
    NSMutableArray * filteredArray =
        [NSMutableArray arrayWithCapacity:self.count];

    for (id candidate in self)
        if ([candidate performSelector:sel withObject:obj])
            [filteredArray addObject:candidate];

    return filteredArray;
}

- (NSArray *)arrayByReversingContents
{
    NSMutableArray * copy = [NSMutableArray arrayWithCapacity:self.count];

    NSEnumerator * iter = [self reverseObjectEnumerator];
    for (id obj in iter)
        [copy addObject:obj];

    return copy;
}

- (NSString *)join:(NSString *)component
{
    NSMutableString * s = [NSMutableString string];
    if (self.count) {
        [s appendString:[[self objectAtIndex:0] description]];
        for (NSInteger i = 1, count = self.count; i < count; ++i) {
            [s appendString:component];
            [s appendString:[[self objectAtIndex:i] description]];
        }
    }

    return s;
}

@end
