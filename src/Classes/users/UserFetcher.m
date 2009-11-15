//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UserFetcher.h"
#import "AsynchronousNetworkFetcher.h"
#import "User+UIAdditions.h"

@interface UserFetcher ()
@property (nonatomic, copy) NSString * username;
@property (nonatomic, retain) User * user;
@end

@implementation UserFetcher

@synthesize delegate, username, service, user;

- (void)dealloc
{
    self.delegate = nil;

    self.username = nil;
    self.service = nil;
    self.user = nil;

    [super dealloc];
}

- (id)initWithUsername:(NSString *)aUsername service:(TwitterService *)aService
{
    if (self = [super init]) {
        self.username = aUsername;
        self.service = aService;
        self.service.delegate = self;
    }

    return self;
}

- (void)fetchUserInfo
{
    [self.service fetchUserInfoForUsername:self.username];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)aUser fetchedForUsername:(NSString *)username
{
    self.user = aUser;
    NSURL * url = [NSURL URLWithString:user.avatar.thumbnailImageUrl];
    [AsynchronousNetworkFetcher fetcherWithUrl:url delegate:self];
}

- (void)failedToFetchUserInfoForUsername:(NSString *)aUsername
                                   error:(NSError *)error
{
    SEL sel = @selector(userUpdater:failedToFetchUser:);
    if ([self.delegate respondsToSelector:sel])
        [self.delegate userUpdater:self failedToFetchUser:error];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    UIImage * avatar = [UIImage imageWithData:data];
    [User setAvatar:avatar forUrl:[url absoluteString]];

    if ([self.delegate respondsToSelector:@selector(userUpdater:fetchedUser:)])
        [self.delegate userUpdater:self fetchedUser:user];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    SEL sel = @selector(userUpdater:failedToFetchUser:);
    if ([self.delegate respondsToSelector:sel])
        [self.delegate userUpdater:self failedToFetchUser:error];
}

@end
