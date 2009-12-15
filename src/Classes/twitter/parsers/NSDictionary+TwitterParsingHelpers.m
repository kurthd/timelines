//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSDictionary+TwitterParsingHelpers.h"

@implementation NSDictionary (TwitterParsingHelpers)

- (id)safeObjectForKey:(id)key
{
    id obj = [self objectForKey:key];
    return [obj isEqual:[NSNull null]] ? nil : obj;
}

@end
