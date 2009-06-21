//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterCredentials : NSObject
{
    NSString * username;
    NSString * password;
}

@property (nonatomic, copy, readonly) NSString * username;
@property (nonatomic, copy, readonly) NSString * password;

+ (id)credentialsWithUsername:(NSString *)aUsername
                     password:(NSString *)aPassword;
- (id)initWithUsername:(NSString *)aUsername password:(NSString *)aPassword;

@end
