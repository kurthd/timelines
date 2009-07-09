//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "User+UIAdditions.h"
#import "AsynchronousNetworkFetcher.h"

@interface User (Private)

+ (NSMutableDictionary *)avatarCache;
+ (NSMutableDictionary *)urlToUsersMapping;

@end

@implementation User (UIAdditions)

static NSMutableDictionary * avatars;
static NSMutableDictionary * urlToUsers;

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

@end
