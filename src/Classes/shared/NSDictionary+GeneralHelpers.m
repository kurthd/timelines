//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSDictionary+GeneralHelpers.h"

@implementation NSDictionary (GeneralHelpers)

- (BOOL)containsKeys:(NSArray *)keys
{
    NSArray * foundObjects = [self objectsForKeys:keys notFoundMarker:self];
    return ![foundObjects containsObject:self];
}

@end
