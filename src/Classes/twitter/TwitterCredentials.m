// 
//  TwitterCredentials.m
//  twitch
//
//  Created by John A. Debay on 7/14/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitterCredentials.h"

#import "ActiveTwitterCredentials.h"
#import "DirectMessage.h"
#import "DirectMessageDraft.h"
#import "Mention.h"
#import "TweetDraft.h"
#import "TwitPicCredentials.h"
#import "UserTweet.h"

@implementation TwitterCredentials 

@dynamic username;
@dynamic directMessages;
@dynamic activeCredentials;
@dynamic userTimeline;
@dynamic tweetDraft;
@dynamic mentions;
@dynamic directMessageDraft;
@dynamic twitPicCredentials;

@end
