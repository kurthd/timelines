//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (TwitterStringHelpers)

+ (NSDate *)dateWithTwitterUserString:(NSString *)s;
+ (NSDate *)dateWithTweetString:(NSString *)s;

@end
