// 
//  TwitterCredentials.m
//  twitch
//
//  Created by John A. Debay on 6/21/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import "TwitterCredentials.h"
#import "SFHFKeychainUtils.h"

@implementation TwitterCredentials 

@dynamic username;

+ (NSString *)keychainServiceName
{
    return @"twitch";
}

- (NSString *)password
{
    NSString * service = [[self class] keychainServiceName];
    NSString * username = self.username;

    NSError * error;
    NSString * password = [SFHFKeychainUtils getPasswordForUsername:username
                                                     andServiceName:service
                                                              error:&error];

    if (error) {
        NSLog(@"Error retrieving password from keychain for user '%@': '%@'.",
            self.username, error);
        return nil;
    }

    return password;
}

- (void)setPassword:(NSString *)password
{
    NSString * service = [[self class] keychainServiceName];

    NSError * error;
    [SFHFKeychainUtils storeUsername:self.username
                         andPassword:password
                      forServiceName:service
                      updateExisting:YES
                               error:&error];

    if (error)
        NSLog(@"Error saving password for user '%@' in keychain: '%@'",
            self.username, error);
}

- (NSString *)description
{
    return self.username;
}

+ (void)deletePasswordForUsername:(NSString *)aUsername
{
    NSString * service = [[self class] keychainServiceName];

    NSError * error;
    [SFHFKeychainUtils deleteItemForUsername:aUsername
                              andServiceName:service
                                       error:&error];

    if (error)
        NSLog(@"Error deleting keychain item for '%@'.: '%@'.", aUsername,
            error);
}

@end
