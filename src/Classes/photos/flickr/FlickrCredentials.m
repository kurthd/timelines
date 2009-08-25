// 
//  FlickrCredentials.m
//  twitch
//
//  Created by John A. Debay on 8/24/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "FlickrCredentials.h"


@implementation FlickrCredentials 

@dynamic username;
@dynamic userId;
@dynamic fullName;
@dynamic token;

- (NSString *)serviceName
{
    return @"Flickr";
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
