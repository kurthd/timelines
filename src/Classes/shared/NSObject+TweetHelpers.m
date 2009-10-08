//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSObject+TweetHelpers.h"

@implementation NSObject (TweetHelpers)

+ (NSComparisonResult)compareTweetId:(NSString *)id1 toId:(NSString *)id2
{
    long long first = [id1 longLongValue];
    long long second = [id2 longLongValue];
    
    if (first < second)
        return NSOrderedAscending;
    else if (first > second)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@end
