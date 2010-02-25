//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSString+UrlAdditions.h"
#import "RegexKitLite.h"

@implementation NSString (UrlAdditions)

- (NSArray *)extractUrls
{
    // Clearing the string cache on every call is unfortunate, but seems to
    // be necessary as calling this function multiple times with the same
    // string as input to the regex seems to return correct results the
    // first time, but incorrect results after that.
    [[self class] clearStringCache];
    return [self componentsMatchedByRegex:[[self class] urlRegex]];
}

- (BOOL)containsUrls
{
    return [self isMatchedByRegex:[[self class] urlRegex]];
}

+ (NSString *)urlRegex
{
    // Should this check for https too?
    return @"\\b(?:http://)[-a-zA-Z0-9+&@#/%?=~_()\\|!:,.;]*";
}

@end
