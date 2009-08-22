//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoService.h"

@class YfrogResponseParser;

@interface YfrogPhotoService : PhotoService
{
    NSString * yfrogUrl;

    NSMutableData * data;
    NSURLConnection * connection;

    YfrogResponseParser * parser;
}

@end