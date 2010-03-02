//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import "TwitterXauthenticator.h"
#import "XAuthTwitterEngine.h"
#import "TwitbitShared.h"

@interface TwitterXauthenticator ()
@property (nonatomic, retain) XAuthTwitterEngine * twitter;
@property (nonatomic, copy) NSString * consumerKey;
@property (nonatomic, copy) NSString * consumerSecret;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;

+ (NSDictionary *)keyValuePairsFromTokenString:(NSString *)tokenString;
@end

@implementation TwitterXauthenticator

@synthesize delegate, consumerKey, consumerSecret, username, password, twitter;

- (void)dealloc
{
    [self setDelegate:nil];

    [self setConsumerKey:nil];
    [self setConsumerSecret:nil];

    [self setUsername:nil];
    [self setPassword:nil];

    [self setTwitter:nil];

    [super dealloc];
}

#pragma mark Public implementation

+ (id)twitbitForIphoneXauthenticator
{
    static NSString * key = @"YSfdtPCIvkvMkItCrc3OsQ";
    static NSString * secret = @"M2mHASraAGv9kRu1KnyAXYb1snEbmRVrqneuHTCeY";

    id obj = [[self alloc] initWithConsumerKey:key consumerSecret:secret];
    return [obj autorelease];
}

- (id)initWithConsumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    if (self = [super init]) {
        [self setConsumerKey:key];
        [self setConsumerSecret:secret];

        XAuthTwitterEngine * engine =
            [XAuthTwitterEngine XAuthTwitterEngineWithDelegate:self];
        [self setTwitter:engine];

        [[self twitter] setConsumerKey:[self consumerKey]];
        [[self twitter] setConsumerSecret:[self consumerSecret]];
    }

    return self;
}

- (void)authWithUsername:(NSString *)user password:(NSString *)pass
{
    [self setUsername:user];
    [self setPassword:pass];

    [[self twitter] exchangeAccessTokenForUsername:[self username]
                                          password:[self password]];
}

#pragma mark XAuthTwitterEngineDelegate implementation

- (void)storeCachedTwitterXAuthAccessTokenString:(NSString *)tokenString
                                     forUsername:(NSString *)user
{
    NSLog(@"token string: '%@'", tokenString);
    NSLog(@"username: '%@'", user);

    NSDictionary * pairs =
        [[self class] keyValuePairsFromTokenString:tokenString];

    NSString * token = [pairs objectForKey:@"oauth_token"];
    NSString * secret = [pairs objectForKey:@"oauth_token_secret"];

    if (token && secret)
        [[self delegate] xauthenticator:self
                        didReceiveToken:token
                              andSecret:secret
                            forUsername:[self username]
                            andPassword:[self password]];
    else {
        // TODO: Localize this string
        NSString * msg = LS(@"xauth.tokenstring.invalid");
        NSString * key = NSLocalizedDescriptionKey;
        NSDictionary * userInfo = [NSDictionary dictionaryWithObject:msg
                                                              forKey:key];
        NSError * error = [NSError errorWithDomain:@"TwitterXAuthErrorDomain"
                                              code:-1
                                          userInfo:userInfo];

        [[self delegate] xauthenticator:self
                   failedToAuthUsername:[self username]
                            andPassword:[self password]
                                  error:error];
    }
}

- (NSString *)cachedTwitterXAuthAccessTokenStringForUsername:(NSString *)user
{
    NSLog(@"username: %@", user);
    return nil;
}

- (void)twitterXAuthConnectionDidFailWithError:(NSError *)error
{
    NSLog(@"connection failed with error: %@", error);

    [[self delegate] xauthenticator:self
               failedToAuthUsername:[self username]
                        andPassword:[self password]
                              error:error];
}

#pragma mark Private implementation

+ (NSDictionary *)keyValuePairsFromTokenString:(NSString *)tokenString
{
    //
    // The token string will look like this (as one concatenated string):
    //
    //   oauth_token=11922782-udWaHkhuuRFM6rYirUdxuWjYoD3WByXGAfmxSbCNp&
    //   oauth_token_secret=49Q8RqH0POwSUSp4KuFwhSM6LuBuaRQEzIuZvGunQos&
    //   user_id=11922782&screen_name=debay&x_auth_expires=0
    //

    NSMutableDictionary * nvpairs = [NSMutableDictionary dictionary];

    NSArray * pairs = [tokenString componentsSeparatedByString:@"&"];
    for (NSString * pair in pairs) {
        NSArray * nvpair = [pair componentsSeparatedByString:@"="];

        if (nvpair && [nvpair count] == 2) {
            NSString * name = [nvpair objectAtIndex:0];
            NSString * value = [nvpair objectAtIndex:1];

            [nvpairs setObject:value forKey:name];
        }
    }

    return nvpairs;
}

@end

