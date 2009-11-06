// 
//  Tweet.m
//  twitch
//
//  Created by John A. Debay on 10/9/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "Tweet.h"

#import "TweetLocation.h"
#import "User.h"

#import "NSObject+TweetHelpers.h"

@implementation Tweet 

@dynamic inReplyToTwitterUsername;
@dynamic source;
@dynamic truncated;
@dynamic favorited;
@dynamic inReplyToTwitterTweetId;
@dynamic identifier;
@dynamic text;
@dynamic timestamp;
@dynamic inReplyToTwitterUserId;
@dynamic location;
@dynamic user;

- (NSComparisonResult)compare:(Tweet *)tweet
{
    return [self.identifier compare:tweet.identifier];
}

@end
