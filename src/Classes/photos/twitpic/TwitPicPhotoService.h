//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"

@class ASIHTTPRequest, ASINetworkQueue, TwitPicResponseParser;

@interface TwitPicPhotoService : PhotoService
{
    NSString * twitPicUrl;

    ASIHTTPRequest * request;
    ASINetworkQueue * queue;

    TwitPicResponseParser * parser;
}

@end
