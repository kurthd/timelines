//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AccountsButtonSetter.h"
#import "TwitbitShared.h"

@interface AccountsButtonSetter ()

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * avatarUrl;

- (void)fetchUserInfoForUsername:(NSString *)aUsername;
- (void)fetchAvatarAtUrl:(NSString *)urlAsString;

@end

@implementation AccountsButtonSetter

@synthesize username;
@synthesize avatarUrl;

- (void)dealloc
{
    [accountsButton release];
    [twitterService release];
    [context release];
    
    [username release];
    [avatarUrl release];

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

    User * user = [User userWithCaseInsensitiveUsername:username
                                                context:context];
    UIImage * avatar = [user thumbnailAvatar];
    if (!avatar)
        avatar = [Avatar defaultAvatar];
    [accountsButton setUsername:self.username avatar:avatar];

    if (user) {
        self.avatarUrl = user.avatar.thumbnailImageUrl;
        [self performSelector:@selector(fetchUserInfoForUsername:)
                   withObject:self.username
                   afterDelay:5];
    } else
        // fetch the user's avatar immediately
        [self fetchUserInfoForUsername:self.username];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)aUsername
{
    if ([aUsername isEqual:self.username])
        // only re-fetch if the avatar URL has changed
        if (![user.avatar.thumbnailImageUrl isEqual:self.avatarUrl])
            [self fetchAvatarAtUrl:user.avatar.thumbnailImageUrl];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    UIImage * avatarImage = [UIImage imageWithData:data];
    [accountsButton setUsername:self.username avatar:avatarImage];
    [User setAvatar:avatarImage forUrl:[url absoluteString]];
}

#pragma mark Private implementation

- (void)fetchUserInfoForUsername:(NSString *)aUsername
{
    [twitterService fetchUserInfoForUsername:aUsername];
}

- (void)fetchAvatarAtUrl:(NSString *)urlAsString
{
    NSURL * url = [NSURL URLWithString:urlAsString];
    [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];
}

@end