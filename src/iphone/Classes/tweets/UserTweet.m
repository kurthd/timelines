// 
//  UserTweet.m
//  twitch
//
//  Created by John A. Debay on 6/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "UserTweet.h"

#import "TwitterCredentials.h"

@implementation UserTweet 

@dynamic credentials;

- (NSString *)description
{
    return [NSString stringWithFormat:@"'%@' recieved: '%@': '%@'",
        self.credentials.username, self.user, self.text];
}

@end
