// 
//  FlickrCredentials.m
//  twitch
//
//  Created by John A. Debay on 8/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "FlickrCredentials.h"

#import "FlickrTag.h"

@implementation FlickrCredentials 

@dynamic username;
@dynamic fullName;
@dynamic userId;
@dynamic token;
@dynamic tags;

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
