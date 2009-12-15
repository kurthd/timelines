//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSNumber+TwitterParsingHelpers.h"

@implementation NSNumber (TwitterParsingHelpers)

- (NSNumber *)twitterIdentifierValue
{
    NSString * desc = [self description];
    long long val = [desc longLongValue];
    return [NSNumber numberWithLongLong:val];
}

@end
