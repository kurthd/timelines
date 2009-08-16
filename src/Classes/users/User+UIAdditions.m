//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "User+UIAdditions.h"
#import "AsynchronousNetworkFetcher.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface User (Private)

//+ (NSMutableDictionary *)avatarCache;
+ (NSMutableDictionary *)urlToUsersMapping;

+ (NSMutableDictionary *)followersDescriptionCache;

@end

@implementation User (UIAdditions)

static NSMutableDictionary * urlToUsers;

static NSMutableDictionary * followersDescriptions;

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * urlAsString = [url absoluteString];
    UIImage * avatarImage = [UIImage imageWithData:data];
    if (avatarImage) {
        NSArray * users =
            [[[self class] urlToUsersMapping] objectForKey:urlAsString];
        for (User * user in users)
            user.avatar.thumbnailImage = data;
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark User (UIAdditions) implementation

- (RoundedImage *)roundedAvatarImage
{
    RoundedImage * roundedAvatarImage =
        [[[RoundedImage alloc] init] autorelease];
    UIImage * userAvatar = [UIImage imageWithData:self.avatar.thumbnailImage];

    if (userAvatar)
        [roundedAvatarImage setImage:userAvatar];
    else {
        NSURL * avatarUrl = [NSURL URLWithString:self.avatar.thumbnailImageUrl];
        [AsynchronousNetworkFetcher fetcherWithUrl:avatarUrl delegate:self];

        NSMutableArray * users =
            [[[self class] urlToUsersMapping]
            objectForKey:self.avatar.thumbnailImageUrl];
        if (!users) {
            users = [NSMutableArray array];
            [[[self class] urlToUsersMapping]
                setObject:users forKey:self.avatar.thumbnailImageUrl];
        }
        if (![users containsObject:self])
            [users addObject:self];
    }

    return roundedAvatarImage;
}

- (UIImage *)avatarImage
{
    return [self roundedAvatarImage].image;
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

+ (void)setAvatar:(UIImage *)image forUrl:(NSString *)url
{
    id delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [delegate managedObjectContext];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"thumbnailImageUrl == %@", url];
    Avatar * avatar = [Avatar findFirst:predicate context:context];
    if (avatar)
        avatar.thumbnailImage = UIImagePNGRepresentation(image);
    else {
        predicate =
            [NSPredicate predicateWithFormat:@"fullImageUrl == %@", url];
        avatar = [Avatar findFirst:predicate context:context];

        if (avatar)
            avatar.fullImage = UIImagePNGRepresentation(image);
    }
}

+ (UIImage *)avatarForUrl:(NSString *)url
{
    UIImage * image = nil;

    id delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [delegate managedObjectContext];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"thumbnailImageUrl == %@", url];
    Avatar * avatar = [Avatar findFirst:predicate context:context];
    if (avatar)
        image = [UIImage imageWithData:avatar.thumbnailImage];
    else {
        predicate =
            [NSPredicate predicateWithFormat:@"fullImageUrl == %@", url];
        avatar = [Avatar findFirst:predicate context:context];

        if (avatar)
            image = [UIImage imageWithData:avatar.fullImage];
    }

    return image;
}

+ (NSString *)largeAvatarUrlForUrl:(NSString *)url
{
    NSString * largeAvatarUrl =
        [url stringByReplacingOccurrencesOfString:@"_normal." withString:@"."];

    return largeAvatarUrl;
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
