//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "Avatar+UIAdditions.h"

@interface Avatar ()

+ (NSMutableDictionary *)actualThumbnailImages;

@end

@implementation Avatar (UIAdditions)

static NSMutableDictionary * actualThumbnailImages;

- (UIImage *)actualThumbnailImage
{
    UIImage * actualImage =
        [[[self class] actualThumbnailImages]
            objectForKey:self.thumbnailImageUrl];
    if (!actualImage) {
        NSData * imageData = self.thumbnailImage;
        actualImage = imageData ? [UIImage imageWithData:imageData] : nil;
        if (actualImage)
            [actualThumbnailImages setObject:actualImage
                forKey:self.thumbnailImageUrl];
    }

    return actualImage;
}

+ (NSMutableDictionary *)actualThumbnailImages
{
    if (!actualThumbnailImages)
        actualThumbnailImages = [[NSMutableDictionary dictionary] retain];

    return actualThumbnailImages;
}

+ (UIImage *)defaultAvatar
{
    static UIImage * defaultAvatar = nil;
    if (!defaultAvatar)
        defaultAvatar = [[UIImage imageNamed:@"DefaultAvatar50x50.png"] retain];

    return defaultAvatar;
}

@end
