//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitVidCredentials+KeychainAdditions.h"
#import "SFHFKeychainUtils.h"

@implementation TwitVidCredentials (KeychainAdditions)

+ (NSString *)keychainServiceName
{
    return @"twitvid";
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

@end