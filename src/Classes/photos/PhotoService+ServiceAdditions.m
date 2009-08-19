//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoService+ServiceAdditions.h"

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

@end
