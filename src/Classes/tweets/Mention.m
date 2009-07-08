// 
//  Mention.m
//  twitch
//
//  Created by John A. Debay on 6/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "Mention.h"

#import "TwitterCredentials.h"

@implementation Mention 

@dynamic credentials;

- (NSString *)description
{
    return [NSString stringWithFormat:@"'%@' was mentioned: '%@': '%@'.",
        self.credentials.username, self.user, self.text];
}

@end
