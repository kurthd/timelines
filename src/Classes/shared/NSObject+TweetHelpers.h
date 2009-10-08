//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tweet.h"

@interface NSObject (TweetHelpers)

/*
 * Returns:
 *   NSOrderedAscending  if id1 < id2
 *   NSOrderedSending    if id1 == id2
 *   NSOrderedDescending if id1 > id2
 */
+ (NSComparisonResult)compareTweetId:(NSString *)id1 toId:(NSString *)id2;

@end
