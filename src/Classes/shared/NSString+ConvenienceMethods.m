//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSString+ConvenienceMethods.h"

@implementation NSString (ConvenienceMethods)

- (BOOL)containsString:(NSString *)s
{
    NSRange notFound = NSMakeRange(NSNotFound, 0);
    NSRange where = [self rangeOfString:s];

    return
        where.location != notFound.location && where.length != notFound.length;
}

@end
