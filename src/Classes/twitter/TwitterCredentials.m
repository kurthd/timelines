// 
//  TwitterCredentials.m
//  twitch
//
//  Created by John A. Debay on 3/18/10.
//  Copyright 2010 High Order Bit, Inc.. All rights reserved.
//

#import "TwitterCredentials.h"

#import "ActiveTwitterCredentials.h"
#import "BitlyCredentials.h"
#import "DirectMessage.h"
#import "DirectMessageDraft.h"
#import "InstapaperCredentials.h"
#import "Mention.h"
#import "PhotoServiceCredentials.h"
#import "TweetDraft.h"
#import "User.h"
#import "UserTweet.h"
#import "UserTwitterList.h"

@implementation TwitterCredentials 

@dynamic username;
@dynamic lists;
@dynamic instapaperCredentials;
@dynamic userTimeline;
@dynamic directMessageDrafts;
@dynamic bitlyCredentials;
@dynamic directMessages;
@dynamic mentions;
@dynamic activeCredentials;
@dynamic tweetDraft;
@dynamic user;
@dynamic photoServiceCredentials;

@end
