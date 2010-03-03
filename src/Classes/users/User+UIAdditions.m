//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "User+UIAdditions.h"
#import "AsynchronousNetworkFetcher.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "Avatar+UIAdditions.h"

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
        NSNumberFormatter * formatter =
            [[[NSNumberFormatter alloc] init] autorelease];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSString * followingString =
            [formatter stringFromNumber:self.friendsCount];
        NSString * followersString =
            [formatter stringFromNumber:self.followersCount];
        followersDescription =
            [NSString stringWithFormat:followingFormatString, followingString,
            followersString];
        [[[self class] followersDescriptionCache]
            setObject:followersDescription forKey:self.identifier];
    }

    return followersDescription;
}

- (UIImage *)thumbnailAvatar
{
    return [self.avatar actualThumbnailImage];
}

- (UIImage *)fullAvatar
{
    NSData * imageData = self.avatar.fullImage;
    return imageData ? [UIImage imageWithData:imageData] : nil;
}

+ (void)setAvatar:(UIImage *)image forUrl:(NSString *)url
{
    // just grabbing the context like this is a total hack
    id delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext * context = [delegate managedObjectContext];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"thumbnailImageUrl == %@", url];
    NSArray * avatars = [Avatar findAll:predicate context:context];
    if (avatars.count == 0) {
        predicate =
            [NSPredicate predicateWithFormat:@"fullImageUrl == %@", url];
        avatars = [Avatar findAll:predicate context:context];
        for (Avatar * avatar in avatars)
            avatar.fullImage = UIImagePNGRepresentation(image);
    } else
        for (Avatar * avatar in avatars)
            avatar.thumbnailImage = UIImagePNGRepresentation(image);
}

+ (NSString *)fullAvatarUrlForUrl:(NSString *)url
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

@implementation User (SortingAdditions)

- (NSComparisonResult)caseInsensitiveUsernameCompare:(User *)otherUser
{
    return [self.username caseInsensitiveCompare:otherUser.username];
}

@end