// 
//  Tweet.m
//  twitch
//
//  Created by John A. Debay on 2/24/10.
//  Copyright 2010 High Order Bit, Inc.. All rights reserved.
//

#import "Tweet.h"

#import "TweetLocation.h"
#import "User.h"

@implementation Tweet 

@dynamic inReplyToTwitterUserId;
@dynamic timestamp;
@dynamic searchResult;
@dynamic source;
@dynamic inReplyToTwitterTweetId;
@dynamic identifier;
@dynamic photoUrlWebpage;
@dynamic favorited;
@dynamic truncated;
@dynamic text;
@dynamic inReplyToTwitterUsername;
@dynamic decodedText;
@dynamic retweet;
@dynamic retweets;
@dynamic location;
@dynamic user;

- (NSComparisonResult)compare:(Tweet *)tweet
{
    return [self.identifier compare:tweet.identifier];
}

@end
