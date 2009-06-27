//
//  UserTweet.h
//  twitch
//
//  Created by John A. Debay on 6/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Tweet.h"

@class TwitterCredentials;

@interface UserTweet :  Tweet  
{
}

@property (nonatomic, retain) TwitterCredentials * credentials;

@end



