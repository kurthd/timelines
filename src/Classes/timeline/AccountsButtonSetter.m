//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AccountsButtonSetter.h"
#import "TwitbitShared.h"

@interface AccountsButtonSetter ()

@property (nonatomic, copy) NSString * username;

@end

@implementation AccountsButtonSetter

@synthesize username;

- (void)dealloc
{
    [accountsButton release];
    [twitterService release];
    [context release];
    
    [username release];

    [super dealloc];
}

- (id)initWithAccountsButton:(AccountsButton *)anAccountsButton
    twitterService:(TwitterService *)aTwitterService
           context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        accountsButton = [anAccountsButton retain];
        twitterService = [aTwitterService retain];
        context = [aContext retain];
    }

    return self;
}

- (void)setButtonWithUsername:(NSString *)aUsername
{
    self.username = aUsername;

    User * user = [User userWithUsername:username context:context];
    UIImage * avatar = user ? [user thumbnailAvatar] : [Avatar defaultAvatar];
    [accountsButton setUsername:self.username avatar:avatar];

    if (!user)
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