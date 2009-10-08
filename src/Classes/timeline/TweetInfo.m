//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetInfo.h"
#import "RegexKitLite.h"
#import "NSString+HtmlEncodingAdditions.h"

static NSString * usernameRegex = @"\\B(@[\\w_]+)";
static NSString * hashRegex = @"\\B(#[\\w_]+)";

static BOOL displayWithUsername;
static BOOL alreadyReadDisplayWithUsernameValue;

@interface TweetInfo ()

+ (NSString *)bodyWithLinks:(NSString *)body;
+ (NSString *)bodyWithUserLinks:(NSString *)body;
+ (NSString *)bodyWithHashLinks:(NSString *)body;
+ (BOOL)displayWithUsername;

@end

@implementation TweetInfo

@synthesize timestamp, truncated, identifier, text, source, user, recipient,
    favorited, inReplyToTwitterUsername, inReplyToTwitterTweetId,
    inReplyToTwitterUserId, location;

- (void)dealloc
{
    [timestamp release];
    [truncated release];
    [identifier release];
    [text release];
    [source release];
    [user release];
    [recipient release];
    [favorited release];
    [inReplyToTwitterUsername release];
    [inReplyToTwitterTweetId release];
    [inReplyToTwitterUserId release];
    [super dealloc];
}

- (NSComparisonResult)compare:(TweetInfo *)tweetInfo
{
    NSNumber * myId =
        [NSNumber numberWithLongLong:[self.identifier longLongValue]];
    NSNumber * theirId =
        [NSNumber numberWithLongLong:[tweetInfo.identifier longLongValue]];

    return [theirId compare:myId];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{%@, %@, %@}", self.user.username,
        self.text, self.timestamp];
}

+ (TweetInfo *)createFromTweet:(Tweet *)tweet
{
    TweetInfo * tweetInfo =
        [[[TweetInfo alloc] init] autorelease];

    tweetInfo.timestamp = tweet.timestamp;
    tweetInfo.truncated = tweet.truncated;
    tweetInfo.identifier = tweet.identifier;
    tweetInfo.text = tweet.text;
    tweetInfo.source = tweet.source;
    tweetInfo.user = tweet.user;
    tweetInfo.recipient = nil;
    tweetInfo.favorited = tweet.favorited;
    tweetInfo.inReplyToTwitterUsername = tweet.inReplyToTwitterUsername;
    tweetInfo.inReplyToTwitterTweetId = tweet.inReplyToTwitterTweetId;
    tweetInfo.inReplyToTwitterUserId = tweet.inReplyToTwitterUserId;

    // TODO: set location
    // tweetInfo.location =
    //     [[[CLLocation alloc] initWithLatitude:45.696768 longitude:-73.578957]
    //     autorelease];

    return tweetInfo;
}

+ (TweetInfo *)createFromDirectMessage:(DirectMessage *)message
{
    TweetInfo * tweetInfo =
        [[[TweetInfo alloc] init] autorelease];

    tweetInfo.timestamp = message.created;
    tweetInfo.truncated = NO;
    tweetInfo.identifier = message.identifier;
    tweetInfo.text = message.text;
    tweetInfo.source = nil;
    tweetInfo.user = message.sender;
    tweetInfo.recipient = message.recipient;
    tweetInfo.favorited = nil;
    tweetInfo.inReplyToTwitterUsername = nil;
    tweetInfo.inReplyToTwitterTweetId = nil;
    tweetInfo.inReplyToTwitterUserId = nil;

    return tweetInfo;
}

- (NSString *)textAsHtml
{
    NSString * body = [[self class] bodyWithLinks:self.text];
    // some tweets have newlines -- convert them to HTML line breaks for
    // display in the HTML tweet view
    body = [body stringByReplacingOccurrencesOfString:@"\n"
                                           withString:@"<br />"];

    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString * timestampAsString = [formatter stringFromDate:self.timestamp];
    [formatter release];

    NSString * sourceString =
        self.source ?
        [NSString stringWithFormat:@"from %@",
        [self.source stringByDecodingHtmlEntities]] :
        @"&nbsp;";

    NSString * html =
        [NSString stringWithFormat:
        @"<html>"
        "  <head>"
        "   <style media=\"screen\" type=\"text/css\" rel=\"stylesheet\">"
        "     @import url(tweet-style.css);"
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
        body, sourceString, timestampAsString];

    return html;
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
    return
        self.recipient ? nil :
        [NSString stringWithFormat:@"http://twitter.com/%@/status/%@",
        self.user.username, self.identifier];
}

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
    NSRange currentRange = [body rangeOfRegex:usernameRegex];
    while (!NSEqualRanges(currentRange, notFoundRange)) {
        NSString * mention = [body substringWithRange:currentRange];
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
        NSString * mentionRegex =
            [NSString stringWithFormat:@"\\B(%@)\\b", mention];
        bodyWithUserLinks =
            [bodyWithUserLinks stringByReplacingOccurrencesOfRegex:mentionRegex
            withString:@"<a href=\"x-twitbit://user?screen_name=$1\">$1</a>"];
    }

    return bodyWithUserLinks;
}

+ (NSString *)bodyWithHashLinks:(NSString *)body
{
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);

    NSMutableDictionary * uniqueMentions = [NSMutableDictionary dictionary];
    NSRange currentRange = [body rangeOfRegex:hashRegex];
    while (!NSEqualRanges(currentRange, notFoundRange)) {
        NSString * mention = [body substringWithRange:currentRange];
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
        NSString * mentionRegex =
            [NSString stringWithFormat:@"\\B(%@)\\b", mention];
        bodyWithHashLinks =
            [bodyWithHashLinks stringByReplacingOccurrencesOfRegex:mentionRegex
            withString:@"<a href=\"x-twitbit://search?query=$1\">$1</a>"];
    }

    return bodyWithHashLinks;
}

+ (BOOL)displayWithUsername
{
    if (!alreadyReadDisplayWithUsernameValue) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSInteger displayNameValAsNumber =
            [defaults integerForKey:@"display_name"];
        displayWithUsername = displayNameValAsNumber;
    }

    alreadyReadDisplayWithUsernameValue = YES;

    return displayWithUsername;
}

@end
