//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSNumber+TwitterParsingHelpers.h"
#import "RegexKitLite.h"

@implementation NSString (TwitterParsingHelpers)

- (NSDate *)twitterDateValue
{
    struct tm theTime;
    strptime([self UTF8String], "%a %b %d %H:%M:%S +0000 %Y", &theTime);
    time_t epochTime = timegm(&theTime);

    // jad: HACK: Search results are returned with a different format
    // than tweets, so if parsing the string failed, try the search
    // results format.
    //
    // This code should be changed to just return the string value and
    // the date can be parsed at a higher level.
    if (epochTime == -1) {
        strptime([self UTF8String], "%a, %d %b %Y %H:%M:%S +0000", &theTime);
        epochTime = timegm(&theTime);
    }

    return [NSDate dateWithTimeIntervalSince1970:epochTime];
}

+ (NSString *)photoUrlWebpageFromTweetText:(NSString *)text
{
    static NSString * imageUrlRegex =
        @"\\bhttp://twitpic.com/[a-zA-Z0-9_]+|"
        "\\bhttp://.*\\.?yfrog.com/[a-zA-Z0-9_]+|"
        "\\bhttp://tinypic.com/[a-zA-Z0-9_]+|"
        "\\bhttp://twitgoo.com/[a-zA-Z0-9_]+|"
        "\\bhttp://mobypicture.com/[a-zA-Z0-9_]+|"
        "\\S+\\.jpg$|\\S+\\.jpeg$|\\S+\\.bmp|\\S+\\.gif|\\S+\\.png";

    return [text stringByMatching:imageUrlRegex];
}

@end
