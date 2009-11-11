// 
//  TwitterCredentials.m
//  twitch
//
//  Created by John A. Debay on 11/10/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitterCredentials.h"

#import "ActiveTwitterCredentials.h"
#import "DirectMessage.h"
#import "DirectMessageDraft.h"
#import "InstapaperCredentials.h"
#import "Mention.h"
#import "PhotoServiceCredentials.h"
#import "TweetDraft.h"
#import "UserTweet.h"
#import "UserTwitterList.h"

@implementation TwitterCredentials 

@dynamic username;
@dynamic directMessages;
@dynamic activeCredentials;
@dynamic userTimeline;
@dynamic directMessageDrafts;
@dynamic lists;
@dynamic tweetDraft;
@dynamic photoServiceCredentials;
@dynamic instapaperCredentials;
@dynamic mentions;

@end
