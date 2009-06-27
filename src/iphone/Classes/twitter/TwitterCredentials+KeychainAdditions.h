//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"

@interface TwitterCredentials (KeychainAdditions)

- (NSString *)password;
- (void)setPassword:(NSString *)password;
+ (void)deletePasswordForUsername:(NSString *)username;

@end