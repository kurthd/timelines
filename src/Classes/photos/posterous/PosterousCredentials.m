// 
//  PosterousCredentials.m
//  twitch
//
//  Created by John A. Debay on 3/15/10.
//  Copyright 2010 High Order Bit, Inc.. All rights reserved.
//

#import "PosterousCredentials.h"


@implementation PosterousCredentials 

@dynamic username;

- (NSString *)serviceName
{
    return @"Posterous";
}

- (NSString *)accountDisplayName
{
    return self.username;
}

- (BOOL)supportsPhotos
{
    return YES;
}

- (BOOL)supportsVideo
{
    return NO;
}

@end
