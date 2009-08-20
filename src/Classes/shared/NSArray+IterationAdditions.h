//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (IterationAdditions)

- (NSArray *)arrayByTransformingObjectsUsingSelector:(SEL)sel;

- (NSArray *)arrayByFilteringObjectsUsingSelector:(SEL)sel;
- (NSArray *)arrayByFilteringObjectsUsingSelector:(SEL)sel withObject:(id)obj;

- (NSArray *)arrayByReversingContents;

@end
