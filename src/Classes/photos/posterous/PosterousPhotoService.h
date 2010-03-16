//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"

@class ASIHTTPRequest, ASINetworkQueue, PosterousResponseParser;

@interface PosterousPhotoService : PhotoService
{
    NSString * posterousUrl;

    PosterousResponseParser * parser;
}

@end
