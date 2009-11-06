//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "Tweet+GeneralHelpers.h"
#import "TwitbitShared.h"
#import "User.h"

static NSString * usernameRegex = @"\\B(@[\\w_]+)";
static NSString * hashRegex = @"\\B(#[\\w_]+)";

@interface Tweet (GeneralHelpersPrivate)
+ (NSString *)bodyWithLinks:(NSString *)body;
+ (NSString *)bodyWithUserLinks:(NSString *)body;
+ (NSString *)bodyWithHashLinks:(NSString *)body;

+ (BOOL)displayWithUsername;
@end


@implementation Tweet (GeneralHelpers)

+ (NSString *)tweetTextAsHtml:(NSString *)text
                    timestamp:(NSDate *)timestamp
                       source:(NSString *)source
{
        NSString * body = [[self class] bodyWithLinks:text];
    // some tweets have newlines -- convert them to HTML line breaks for
    // display in the HTML tweet view
    body = [body stringByReplacingOccurrencesOfString:@"\n"
                                           withString:@"<br />"];

    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString * timestampAsString = [formatter stringFromDate:timestamp];
    [formatter release];

    NSString * sourceString =
        source ?
        [NSString stringWithFormat:@"from %@",
        [source stringByDecodingHtmlEntities]] :
        @"&nbsp;";

    NSString * cssFile =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        @"dark-theme-tweet-style.css" :
        @"tweet-style.css";

    NSString * html =
        [NSString stringWithFormat:
        @"<html>"
        "  <head>"
        "   <style media=\"screen\" type=\"text/css\" rel=\"stylesheet\">"
        "     @import url(%@);"
        "   </style>"
        "  </head>"
        "  <body>"
        "    <p class=\"text\">%@</p>"
        "    <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" "
        "      width=\"100%%\" class=\"footer\">"
        "      <tr>"
        "        <td align=\"left\" valign=\"top\">%@</td>"
        "        <td align=\"right\" valign=\"top\">%@</td>"
        "      </tr>"
        "    </table>"
        "  </body>"
        "</html>",
        cssFile, body, sourceString, timestampAsString];

    return html;
}

- (NSString *)textAsHtml
{
    return [[self class] tweetTextAsHtml:self.text
                               timestamp:self.timestamp
                                  source:self.source];
}

- (NSString *)displayName
{
    return
        self.user.name && self.user.name.length > 0 &&
        ![[self class] displayWithUsername] ?
        self.user.name : self.user.username;
}

- (NSString *)tweetUrl
{
    return [NSString stringWithFormat:@"http://twitter.com/%@/status/%@",
        self.user.username, self.identifier];
}

#pragma mark Private implementation

+ (NSString *)bodyWithLinks:(NSString *)body
{
    return
        [[self class] bodyWithHashLinks:[[self class] bodyWithUserLinks:body]];
}

// This implementation is a bit of a hack to get around a RegexKitLite
// limitation: there's a limit to how many strings can be replaced
// If not for the bug, the implementation would be:
//     return [body stringByReplacingOccurrencesOfRegex:usernameRegex
//         withString:@"<a href=\"#$1\">$1</a>"];
+ (NSString *)bodyWithUserLinks:(NSString *)body
{
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);

    NSMutableDictionary * uniqueMentions = [NSMutableDictionary dictionary];
    NSMutableDictionary * excludedMentions = [NSMutableDictionary dictionary];

    NSRange currentRange = [body rangeOfRegex:usernameRegex];
    while (!NSEqualRanges(currentRange, notFoundRange)) {
        NSString * mention = [body substringWithRange:currentRange];
        if ([uniqueMentions objectForKey:mention])
            [excludedMentions setObject:mention forKey:mention];
        [uniqueMentions setObject:mention forKey:mention];

        NSUInteger startingPosition =
            currentRange.location + currentRange.length;
        if (startingPosition < [body length]) {
            NSRange remainingRange =
                NSMakeRange(startingPosition, [body length] - startingPosition);
            currentRange =
                [body rangeOfRegex:usernameRegex inRange:remainingRange];
        } else
            currentRange = notFoundRange;
    }

    NSString * bodyWithUserLinks = [[body copy] autorelease];
    for (NSString * mention in [uniqueMentions allKeys]) {
        if (![excludedMentions objectForKey:mention]) {
            NSString * mentionRegex =
                [NSString stringWithFormat:@"\\B(%@)\\b", mention];
            bodyWithUserLinks =
                [bodyWithUserLinks
                stringByReplacingOccurrencesOfRegex:mentionRegex
                withString:
                @"<a href=\"x-twitbit://user?screen_name=$1\">$1</a>"];
        }
    }

    return bodyWithUserLinks;
}

+ (NSString *)bodyWithHashLinks:(NSString *)body
{
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);

    NSMutableDictionary * uniqueMentions = [NSMutableDictionary dictionary];
    NSMutableDictionary * excludedMentions = [NSMutableDictionary dictionary];

    NSRange currentRange = [body rangeOfRegex:hashRegex];
    while (!NSEqualRanges(currentRange, notFoundRange)) {
        NSString * mention = [body substringWithRange:currentRange];
        if ([uniqueMentions objectForKey:mention])
            [excludedMentions setObject:mention forKey:mention];            
        [uniqueMentions setObject:mention forKey:mention];

        NSUInteger startingPosition =
            currentRange.location + currentRange.length;
        if (startingPosition < [body length]) {
            NSRange remainingRange =
                NSMakeRange(startingPosition, [body length] - startingPosition);
            currentRange =
                [body rangeOfRegex:hashRegex inRange:remainingRange];
        } else
            currentRange = notFoundRange;
    }

    NSString * bodyWithHashLinks = [[body copy] autorelease];
    for (NSString * mention in [uniqueMentions allKeys]) {
        if (![excludedMentions objectForKey:mention]) {
            NSString * mentionRegex =
                [NSString stringWithFormat:@"\\B(%@)\\b", mention];
            bodyWithHashLinks =
                [bodyWithHashLinks
                stringByReplacingOccurrencesOfRegex:mentionRegex
                withString:@"<a href=\"x-twitbit://search?query=$1\">$1</a>"];
        }
    }

    return bodyWithHashLinks;
}

+ (BOOL)displayWithUsername
{
    static NSInteger displayWithUsername = -1;

    if (displayWithUsername == -1) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        displayWithUsername =
            [defaults integerForKey:@"display_name"];
    }

    return displayWithUsername == 1;
}

@end
