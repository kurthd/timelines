// 
//  Tweet.m
//  twitch
//
//  Created by John A. Debay on 6/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "Tweet.h"

#import "User.h"

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
@dynamic user;

- (NSComparisonResult)compare:(Tweet *)tweet
{
    NSNumber * myId =
        [NSNumber numberWithLongLong:[self.identifier longLongValue]];
    NSNumber * theirId =
        [NSNumber numberWithLongLong:[tweet.identifier longLongValue]];

    return [theirId compare:myId];
}

@end
