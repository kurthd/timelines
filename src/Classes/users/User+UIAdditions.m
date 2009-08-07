//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "User+UIAdditions.h"
#import "AsynchronousNetworkFetcher.h"

@interface User (Private)

+ (NSMutableDictionary *)avatarCache;
+ (NSMutableDictionary *)urlToUsersMapping;

+ (NSMutableDictionary *)followersDescriptionCache;

@end

@implementation User (UIAdditions)

static NSMutableDictionary * avatars;
static NSMutableDictionary * urlToUsers;

static NSMutableDictionary * followersDescriptions;

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * urlAsString = [url absoluteString];
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        NSArray * identifiers =
            [[[self class] urlToUsersMapping] objectForKey:urlAsString];
        for (NSString * userIdentifier in identifiers) {
            RoundedImage * roundedImage =
                [[[self class] avatarCache] objectForKey:userIdentifier];
            [roundedImage setImage:avatarImage];
        }
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark User (UIAdditions) implementation

- (RoundedImage *)avatar
{
    RoundedImage * userAvatar =
        [[[self class] avatarCache] objectForKey:self.identifier];
    if (!userAvatar) {
        NSURL * avatarUrl = [NSURL URLWithString:self.profileImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];

        NSMutableArray * userIdentifiers =
            [[[self class] urlToUsersMapping]
            objectForKey:self.profileImageUrl];
        if (!userIdentifiers) {
            userIdentifiers = [NSMutableArray array];
            [[[self class] urlToUsersMapping]
                setObject:userIdentifiers forKey:self.profileImageUrl];
        }
        if (![userIdentifiers containsObject:self.identifier])
            [userIdentifiers addObject:self.identifier];

        userAvatar = [[[RoundedImage alloc] init] autorelease];
        [[[self class] avatarCache]
            setObject:userAvatar forKey:self.identifier];
    }

    return userAvatar;
}

- (UIImage *)avatarImage
{
    return [self avatar].image;
}

- (NSString *)followersDescription
{
    NSString * followersDescription =
        [[[self class] followersDescriptionCache] objectForKey:self.identifier];

    if (!followersDescription) {
        NSString * followingFormatString =
            NSLocalizedString(@"userlisttableview.following", @"");
        followersDescription =
            [NSString stringWithFormat:followingFormatString, self.friendsCount,
            self.followersCount];
        [[[self class] followersDescriptionCache]
            setObject:followersDescription forKey:self.identifier];
    }

    return followersDescription;
}

+ (NSMutableDictionary *)avatarCache
{
    if (!avatars)
        avatars = [[NSMutableDictionary dictionary] retain];

    return avatars;
}

+ (NSMutableDictionary *)urlToUsersMapping
{
    if (!urlToUsers)
        urlToUsers = [[NSMutableDictionary dictionary] retain];

    return urlToUsers;
}

+ (NSMutableDictionary *)followersDescriptionCache
{
    if (!followersDescriptions)
        followersDescriptions = [[NSMutableDictionary dictionary] retain];

    return followersDescriptions;
}

@end
