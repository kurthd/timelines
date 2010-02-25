// 
//  DirectMessage.m
//  twitch
//
//  Created by John A. Debay on 2/24/10.
//  Copyright 2010 High Order Bit, Inc.. All rights reserved.
//

#import "DirectMessage.h"

#import "TwitterCredentials.h"
#import "User.h"

@implementation DirectMessage 

@dynamic created;
@dynamic identifier;
@dynamic text;
@dynamic photoUrlWebpage;
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

- (NSComparisonResult)compare:(DirectMessage *)dm
{
    return [self.identifier compare:dm.identifier];
}

@end
