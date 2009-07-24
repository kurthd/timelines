//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitterCredentials+KeychainAdditions.h"
#import "SFHFKeychainUtils.h"

@implementation TwitterCredentials (KeychainAdditions)

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

+ (void)deleteKeyAndSecretForUsername:(NSString *)username
{
    [self deletePasswordForUsername:username];
}

- (NSString *)key
{
    NSString * password = [self password];
    NSRange where = [password rangeOfString:@" "];
    if (where.location == NSNotFound && where.length == 0)
        return nil;

    return [password substringWithRange:NSMakeRange(0, where.location)];
}

- (NSString *)secret
{
    NSString * password = [self password];
    NSRange where = [password rangeOfString:@" "];
    if (where.location == NSNotFound && where.length == 0)
        return nil;

    NSRange secretRange =
        NSMakeRange(where.location + 1, password.length - (where.location + 1));
    return [password substringWithRange:secretRange];
}

- (void)setKey:(NSString *)key andSecret:(NSString *)secret
{
    NSString * password = [NSString stringWithFormat:@"%@ %@",
        key, secret];
    [self setPassword:password];
}

@end
