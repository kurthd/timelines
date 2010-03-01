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

- (NSComparisonResult)compare:(Tweet *)t
{
    NSNumber * id1 = self.retweet ? self.retweet.identifier : self.identifier;
    NSNumber * id2 = t.retweet ? t.retweet.identifier : t.identifier;

    return [id1 compare:id2];
}

@end
