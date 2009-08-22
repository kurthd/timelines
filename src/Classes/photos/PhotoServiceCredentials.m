// 
//  PhotoServiceCredentials.m
//  twitch
//
//  Created by John A. Debay on 8/18/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "PhotoServiceCredentials.h"

#import "TwitterCredentials.h"

@implementation PhotoServiceCredentials 

@dynamic credentials;

- (NSString *)serviceName
{
    // to be overridden by subclasses
    return nil;
}

- (NSString *)accountDisplayName
{
    // to be overridden by subclasses
    return nil;
}

- (BOOL)supportsPhotos
{
    // to be overridden by subclasses
    return NO;
}

- (BOOL)supportsVideo
{
    // to be overridden by subclasses
    return NO;
}

@end
