//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService+ServiceAdditions.h"
#import "NSObject+RuntimeAdditions.h"
#import "UIApplication+ConfigurationAdditions.h"

@implementation PhotoService (ServiceAdditions)


+ (NSDictionary *)freePhotoServiceNamesAndLogos
{
    return
        [NSDictionary dictionaryWithObjectsAndKeys:
            [UIImage imageNamed:@"TwitPicLogo.png"], @"TwitPic",
            [UIImage imageNamed:@"YfrogLogo.png"], @"Yfrog",
            [UIImage imageNamed:@"TwitVidLogo.png"], @"TwitVid",
            nil];
}

+ (NSDictionary *)premiumPhotoServiceNamesAndLogos
{
    //
    // This is where we restrict the set of photo services available in the
    // free version.
    //

    if ([[UIApplication sharedApplication] isLiteVersion])
        return nil;
    else
        return [NSDictionary dictionaryWithObjectsAndKeys:
            [UIImage imageNamed:@"FlickrLogo.png"], @"Flickr",
            [UIImage imageNamed:@"PicasaLogo.png"], @"Picasa",
            [UIImage imageNamed:@"PosterousLogo.png"], @"Posterous",
            nil];
}

+ (id)photoServiceWithServiceName:(NSString *)serviceName
{
    static NSDictionary * serviceClassNames = nil;
    if (!serviceClassNames)
        serviceClassNames =
            [[NSDictionary alloc] initWithObjectsAndKeys:
            @"TwitPicPhotoService", @"TwitPic",
            @"TwitVidPhotoService", @"TwitVid",
            @"YfrogPhotoService", @"Yfrog",
            @"FlickrPhotoService", @"Flickr",
            @"FlickrPhotoService", @"Picasa",
            @"PosterousPhotoService", @"Posterous",
            nil];

    NSString * className = [serviceClassNames objectForKey:serviceName];
    NSAssert1(className, @"Failed to find class name for service name: '%@'.",
        serviceName);

    Class class = [self classNamed:className];
    return [[[class alloc] init] autorelease];
}

@end
