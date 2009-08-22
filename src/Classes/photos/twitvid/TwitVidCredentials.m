// 
//  TwitVidCredentials.m
//  twitch
//
//  Created by John A. Debay on 8/20/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitVidCredentials.h"


@implementation TwitVidCredentials 

@dynamic username;

- (NSString *)serviceName
{
    return @"TwitVid";
}

- (NSString *)accountDisplayName
{
    return self.username;
}

- (BOOL)supportsPhotos
{
    return NO;
}

- (BOOL)supportsVideo
{
    return YES;
}

@end
