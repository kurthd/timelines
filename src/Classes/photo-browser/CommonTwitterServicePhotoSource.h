//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousNetworkFetcherDelegate.h"
#import "PhotoSource.h"
#import "PhotoSourceDelegate.h"

@interface CommonTwitterServicePhotoSource :
    NSObject <AsynchronousNetworkFetcherDelegate, PhotoSource>
{
    NSObject<PhotoSourceDelegate> * delegate;
    NSMutableDictionary * urlMapping;
}

@property (nonatomic, assign) NSObject<PhotoSourceDelegate> * delegate;

+ (NSString *)photoUrlFromPageHtml:(NSString *)html url:(NSString *)url;

@end
