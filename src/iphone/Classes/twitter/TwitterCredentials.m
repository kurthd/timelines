// 
//  TwitterCredentials.m
//  twitch
//
//  Created by John A. Debay on 6/28/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitterCredentials.h"

#import "ActiveTwitterCredentials.h"
#import "DirectMessage.h"
#import "Mention.h"
#import "TwitPicCredentials.h"
#import "UserTweet.h"

@implementation TwitterCredentials 

@dynamic username;
@dynamic activeCredentials;
@dynamic userTimeline;
@dynamic directMessages;
@dynamic mentions;
@dynamic twitpicCredentials;

@end
