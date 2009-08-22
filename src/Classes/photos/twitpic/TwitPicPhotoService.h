//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"

@class TwitPicResponseParser;

@interface TwitPicPhotoService : PhotoService
{
    NSString * twitPicUrl;

    NSMutableData * data;
    NSURLConnection * connection;

    TwitPicResponseParser * parser;
}

@end