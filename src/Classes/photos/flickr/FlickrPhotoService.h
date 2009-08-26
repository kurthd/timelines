//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"
#import "ObjectiveFlickr.h"

@interface FlickrPhotoService : PhotoService <OFFlickrAPIRequestDelegate>
{
    OFFlickrAPIContext * flickrContext;

    OFFlickrAPIRequest * uploadRequest;
    OFFlickrAPIRequest * editRequest;

    // HACK
    BOOL settingPhotoTitle;
    BOOL settingVideoTitle;
}

+ (NSString *)apiKey;
+ (NSString *)sharedSecret;

@end
