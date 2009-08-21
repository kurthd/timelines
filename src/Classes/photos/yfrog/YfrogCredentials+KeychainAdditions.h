//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YfrogCredentials.h"

@interface YfrogCredentials (KeychainAdditions)

- (NSString *)password;
- (void)setPassword:(NSString *)password;

@end