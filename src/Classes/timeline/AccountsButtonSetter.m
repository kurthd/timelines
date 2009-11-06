//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AccountsButtonSetter.h"

@interface AccountsButtonSetter ()

@property (nonatomic, copy) NSString * username;

@end

@implementation AccountsButtonSetter

@synthesize username;

- (void)dealloc
{
    [accountsButton release];
    [twitterService release];
    
    [username release];

    [super dealloc];
}

- (id)initWithAccountsButton:(AccountsButton *)anAccountsButton
    twitterService:(TwitterService *)aTwitterService
{
    if (self = [super init]) {
        accountsButton = [anAccountsButton retain];
        twitterService = [aTwitterService retain];
    }

    return self;
}

- (void)setButtonWithUsername:(NSString *)aUsername
{
    self.username = aUsername;
    UIImage * defaultAvatar = [UIImage imageNamed:@"DefaultAvatar.png"];
    [accountsButton setUsername:self.username avatar:defaultAvatar];
    [twitterService fetchUserInfoForUsername:aUsername];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)aUsername
{
    if ([aUsername isEqual:self.username]) {
        NSURL * avatarUrl = [NSURL URLWithString:user.avatar.thumbnailImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
    }
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    UIImage * avatarImage = [UIImage imageWithData:data];
    [accountsButton setUsername:self.username avatar:avatarImage];
}

@end
