//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitterCredentials.h"

@interface TwitterCredentials ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;

@end

@implementation TwitterCredentials

@synthesize username, password;

+ (id)credentialsWithUsername:(NSString *)aUsername
                     password:(NSString *)aPassword
{
    id obj = [[[self class] alloc] initWithUsername:aUsername
                                           password:aPassword];
    return [obj autorelease];
}

- (void)dealloc
{
    self.username = nil;
    self.password = nil;
    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername password:(NSString *)aPassword
{
    if (self = [super init]) {
        self.username = aUsername;
        self.password = aPassword;
    }

    return self;
}

@end
