//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DirectMessage+GeneralHelpers.h"
#import "Tweet+GeneralHelpers.h"
#import "TwitbitShared.h"

static NSMutableDictionary * photoUrlWebpageDict;
static NSMutableDictionary * photoUrlDict;

@interface DirectMessage ()

+ (NSMutableDictionary *)photoUrlWebpageDict;
+ (NSMutableDictionary *)photoUrlDict;

@end

@implementation DirectMessage (GeneralHelpers)

- (NSString *)textAsHtml
{
    return [Tweet tweetTextAsHtml:self.text timestamp:self.created source:nil
        photoUrl:[self photoUrl] photoUrlWebpage:[self photoUrlWebpage]];
}

- (NSString *)htmlDecodedText
{
    return [self.text stringByDecodingHtmlEntities];
}

- (NSString *)photoUrl
{
    return [[[self class] photoUrlDict] objectForKey:self.identifier];
}

- (void)setPhotoUrl:(NSString *)photoUrl
{
    [[[self class] photoUrlDict] setObject:photoUrl forKey:self.identifier];
}

- (NSString *)photoUrlWebpage
{
    static NSString * noPhotoUrlsString = @"nil";
    NSString * photoUrl =
        [[[self class] photoUrlWebpageDict] objectForKey:self.identifier];
    if (!photoUrl) {
        static NSString * imageUrlRegex =
            @"\\bhttp://twitpic.com/\\S+|"
            "\\bhttp://.*\\.?yfrog.com/\\S+|"
            "\\bhttp://tinypic.com/\\S+|"
            "\\bhttp://twitgoo.com/\\S+|"
            "\\bhttp://mobypicture.com/\\S+|"
            "\\.jpg$|\\.jpeg$|\\.bmp|\\.gif|\\.png";

        photoUrl = [self.text stringByMatching:imageUrlRegex];
        if (photoUrl)
            [[[self class] photoUrlWebpageDict]
                setObject:photoUrl forKey:self.identifier];
        else
            [[[self class] photoUrlWebpageDict]
                setObject:noPhotoUrlsString forKey:self.identifier];
    } else if ([photoUrl isEqual:noPhotoUrlsString])
        photoUrl = nil;

    return photoUrl;
}

+ (NSMutableDictionary *)photoUrlWebpageDict
{
    if (!photoUrlWebpageDict)
        photoUrlWebpageDict = [[NSMutableDictionary dictionary] retain];

    return photoUrlWebpageDict;
}

+ (NSMutableDictionary *)photoUrlDict
{
    if (!photoUrlDict)
        photoUrlDict = [[NSMutableDictionary dictionary] retain];

    return photoUrlDict;
}

@end