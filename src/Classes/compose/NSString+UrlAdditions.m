//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSString+UrlAdditions.h"
#import "RegexKitLite.h"

@implementation NSString (UrlAdditions)

- (NSArray *)extractUrls
{
    return [self componentsMatchedByRegex:[[self class] urlRegex]];
}

- (BOOL)containsUrls
{
    return [self isMatchedByRegex:[[self class] urlRegex]];
}

+ (NSString *)urlRegex
{
    return @"\\b(?:http://)[-a-zA-Z0-9+&@#/%?=~_()|!:,.;]*";
}

@end
