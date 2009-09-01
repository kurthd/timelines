//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstapaperCredentials.h"

@interface InstapaperCredentials (KeychainAdditions)

- (NSString *)password;
- (void)setPassword:(NSString *)password;

@end