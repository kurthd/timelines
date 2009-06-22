//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSDate+TwitterStringHelpers.h"
#import "NSDate+StringHelpers.h"

@implementation NSDate (TwitterStringHelpers)

+ (NSDate *)dateWithTwitterUserString:(NSString *)s
{
    // Example string: Mon Feb 11 04:41:50 +0000 2008
    static NSString * FORMAT_STRING = @"EEE MMM dd HH:mm:SS ZZZ yyyy";

    return [NSDate dateFromString:s format:FORMAT_STRING];
}

+ (NSDate *)dateWithTweetString:(NSString *)s
{
    // Example string: 2009-06-21 16:00:26 -0600
    static NSString * FORMAT_STRING = @"yyyy-MM-dd HH:mm:SS ZZZ";

    return [NSDate dateFromString:s format:FORMAT_STRING];
}

@end
