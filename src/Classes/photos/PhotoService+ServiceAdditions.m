//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService+ServiceAdditions.h"
#import "NSObject+RuntimeAdditions.h"

@implementation PhotoService (ServiceAdditions)

+ (NSDictionary *)photoServiceNamesAndLogos
{
    return
        [NSDictionary dictionaryWithObjectsAndKeys:
        [UIImage imageNamed:@"FlickrLogo.png"], @"Flickr",
        [UIImage imageNamed:@"TwitPicLogo.png"], @"TwitPic",
        [UIImage imageNamed:@"YfrogLogo.png"], @"Yfrog",
        [UIImage imageNamed:@"TwitVidLogo.png"], @"TwitVid",
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
            nil];

    NSString * className = [serviceClassNames objectForKey:serviceName];
    NSAssert1(className, @"Failed to find class name for service name: '%@'.",
        serviceName);

    Class class = [self classNamed:className];
    return [[[class alloc] init] autorelease];
}

@end
