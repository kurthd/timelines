//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "Tweet+GeneralHelpers.h"
#import "TwitbitShared.h"
#import "User.h"
#import "SettingsReader.h"

static NSMutableDictionary * photoUrlDict;

@interface Tweet (GeneralHelpersPrivate)
+ (NSString *)bodyWithLinks:(NSString *)body;
+ (NSString *)bodyWithUserLinks:(NSString *)body;
+ (NSString *)bodyWithHashLinks:(NSString *)body;

+ (NSMutableDictionary *)photoUrlDict;

+ (BOOL)displayWithUsername;
@end

@implementation Tweet (GeneralHelpers)

+ (NSString *)tweetTextAsHtml:(NSString *)text
                    timestamp:(NSDate *)timestamp
                       source:(NSString *)source
                     photoUrl:(NSString *)photoUrl
              photoUrlWebpage:(NSString *)photoUrlWebpage
{
    NSString * body = [self bodyWithLinks:text];
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

    if (!photoUrl && photoUrlWebpage)
        photoUrl = [SettingsReader displayTheme] == kDisplayThemeDark ?
            @"PhotoPlaceholderDarkTheme.png" : @"PhotoPlaceholder.png";

    NSString * html =
        !photoUrl ?
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
        cssFile, body, sourceString, timestampAsString] :
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
        "      <a href=\"%@\"><img src=\"%@\" class=\"photo\"/></a>"
        "      <tr>"
        "        <td align=\"left\" valign=\"top\">%@</td>"
        "        <td align=\"right\" valign=\"top\">%@</td>"
        "      </tr>"
        "    </table>"
        "  </body>"
        "</html>",
        cssFile, body, photoUrlWebpage, photoUrl, sourceString,
        timestampAsString];

    return html;
}

- (NSString *)textAsHtml
{
    return [[self class] tweetTextAsHtml:self.text
                               timestamp:self.timestamp
                                  source:self.source
                                photoUrl:[self photoUrl]
                         photoUrlWebpage:[self photoUrlWebpage]];
}

- (NSString *)htmlDecodedText
{
    return self.decodedText;
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

- (NSString *)photoUrl
{
    return [[[self class] photoUrlDict] objectForKey:self.identifier];
}

- (void)setPhotoUrl:(NSString *)photoUrl
{
    [[[self class] photoUrlDict] setObject:photoUrl forKey:self.identifier];
}

#pragma mark Private implementation

+ (NSString *)bodyWithLinks:(NSString *)body
{
    return
        [[self class] bodyWithHashLinks:[[self class] bodyWithUserLinks:body]];
}

+ (NSString *)bodyWithUserLinks:(NSString *)body
{
    static NSString * UsernameRegex = @"\\B(@[\\w_]+)";
    static NSString * ReplacementString =
        @"<a href=\"x-twitbit://user?screen_name=$1\">$1</a>";
    return [body stringByReplacingOccurrencesOfRegex:UsernameRegex
                                          withString:ReplacementString];
}

+ (NSString *)bodyWithHashLinks:(NSString *)body
{
    static NSString * HashRegex = @"\\B(#[\\w_]+)";
    static NSString * ReplacementString =
        @"<a href=\"x-twitbit://search?query=$1\">$1</a>";
    return [body stringByReplacingOccurrencesOfRegex:HashRegex
                                          withString:ReplacementString];
}

+ (NSMutableDictionary *)photoUrlDict
{
    if (!photoUrlDict)
        photoUrlDict = [[NSMutableDictionary dictionary] retain];

    return photoUrlDict;
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
