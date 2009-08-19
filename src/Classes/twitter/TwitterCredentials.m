// 
//  TwitterCredentials.m
//  twitch
//
//  Created by John A. Debay on 8/18/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitterCredentials.h"

#import "ActiveTwitterCredentials.h"
#import "DirectMessage.h"
#import "DirectMessageDraft.h"
#import "Mention.h"
#import "PhotoServiceCredentials.h"
#import "TweetDraft.h"
#import "UserTweet.h"

@implementation TwitterCredentials 

@dynamic username;
@dynamic activeCredentials;
@dynamic userTimeline;
@dynamic directMessageDrafts;
@dynamic tweetDraft;
@dynamic mentions;
@dynamic photoServiceCredentials;
@dynamic directMessages;

@end
