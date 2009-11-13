// 
//  TwitterList.m
//  twitch
//
//  Created by John A. Debay on 11/10/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitterList.h"

#import "User.h"

@implementation TwitterList 

@dynamic slug;
@dynamic memberCount;
@dynamic subscriberCount;
@dynamic mode;
@dynamic fullName;
@dynamic identifier;
@dynamic name;
@dynamic uri;
@dynamic user;

- (NSComparisonResult)compare:(TwitterList *)list
{
    return [self.fullName compare:list.fullName];
}

@end
