// 
//  DirectMessage.m
//  twitch
//
//  Created by John A. Debay on 6/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "DirectMessage.h"

#import "TwitterCredentials.h"
#import "User.h"

@implementation DirectMessage 

@dynamic created;
@dynamic identifier;
@dynamic text;
@dynamic sourceApiRequestType;
@dynamic sender;
@dynamic credentials;
@dynamic recipient;

- (NSString *)description
{
    return [NSString stringWithFormat:@"DM for '%@': '%@' -> '%@': '%@'.",
        self.credentials.username, self.sender.username,
        self.recipient.username, self.text];
}

@end
