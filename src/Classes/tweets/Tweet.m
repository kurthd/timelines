// 
//  Tweet.m
//  twitch
//
//  Created by John A. Debay on 11/15/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "Tweet.h"

#import "TweetLocation.h"
#import "User.h"

@implementation Tweet 

@dynamic inReplyToTwitterUserId;
@dynamic timestamp;
@dynamic source;
@dynamic inReplyToTwitterTweetId;
@dynamic identifier;
@dynamic favorited;
@dynamic truncated;
@dynamic text;
@dynamic inReplyToTwitterUsername;
@dynamic decodedText;
@dynamic location;
@dynamic user;

- (NSComparisonResult)compare:(Tweet *)tweet
{
    return [self.identifier compare:tweet.identifier];
}

@end
