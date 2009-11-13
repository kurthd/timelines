//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AccountsButtonSetter.h"
#import "TwitbitShared.h"

@interface AccountsButtonSetter ()

@property (nonatomic, copy) NSString * username;

- (void)fetchUserInfoForUsername:(NSString *)aUsername;
- (void)fetchAvatarAtUrl:(NSString *)urlAsString;

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
    UIImage * avatar = [user thumbnailAvatar];
    if (!avatar)
        avatar = [Avatar defaultAvatar];
    [accountsButton setUsername:self.username avatar:avatar];

    if (!user)
        [self fetchUserInfoForUsername:self.username];
    else if (![user thumbnailAvatar])
        [self fetchAvatarAtUrl:user.avatar.thumbnailImageUrl];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)aUsername
{
    if ([aUsername isEqual:self.username])
        [self fetchAvatarAtUrl:user.avatar.thumbnailImageUrl];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    UIImage * avatarImage = [UIImage imageWithData:data];
    [accountsButton setUsername:self.username avatar:avatarImage];
}

#pragma mark Private implementation

- (void)fetchUserInfoForUsername:(NSString *)aUsername
{
    [twitterService fetchUserInfoForUsername:aUsername];
}

- (void)fetchAvatarAtUrl:(NSString *)urlAsString
{
    NSURL * avatarUrl = [NSURL URLWithString:urlAsString];
    [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];
}

@end