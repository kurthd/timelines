//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSNumber+EncodingAdditions.h"

@implementation NSNumber (EncodingAdditions)

- (NSString *)encodeWithAlphabet:(NSString *)alphabet
{
    long long num = [self longLongValue];
    NSInteger baseCount = [alphabet length];
	NSString * encoded = @"";
	while(num >= baseCount) {
		double div = num / baseCount;
		long long mod = (num - (baseCount * (long long) div));
		NSString * alphabetChar =
            [alphabet substringWithRange:NSMakeRange(mod, 1)];
		encoded = [NSString stringWithFormat:@"%@%@", alphabetChar, encoded];
		num = (long long) div;
	}

	if(num)
		encoded =
            [NSString stringWithFormat: @"%@%@",
            [alphabet substringWithRange: NSMakeRange(num, 1)], encoded];

	return encoded;
}

- (NSString *)base58EncodedString
{
    static NSString * alphabet =
        @"123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
    return [self encodeWithAlphabet:alphabet];
}

@end