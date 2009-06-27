//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetInfo.h"

@implementation TweetInfo

@synthesize timestamp, truncated, identifier, text, source, user, recipient,
    favorited, inReplyToTwitterUsername, inReplyToTwitterTweetId,
    inReplyToTwitterUserId;

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

@end
