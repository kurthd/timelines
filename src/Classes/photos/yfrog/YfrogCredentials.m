// 
//  YfrogCredentials.m
//  twitch
//
//  Created by John A. Debay on 8/20/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "YfrogCredentials.h"


@implementation YfrogCredentials 

@dynamic username;

- (NSString *)serviceName
{
    return @"Yfrog";
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
    return YES;
}

@end
