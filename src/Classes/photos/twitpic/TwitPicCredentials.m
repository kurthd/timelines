// 
//  TwitPicCredentials.m
//  twitch
//
//  Created by John A. Debay on 8/18/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitPicCredentials.h"


@implementation TwitPicCredentials 

@dynamic username;

- (NSString *)serviceName
{
    return @"TwitPic";
}

- (NSString *)accountDisplayName
{
    return self.username;
}

@end
