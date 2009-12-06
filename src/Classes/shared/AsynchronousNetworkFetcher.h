//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousNetworkFetcherDelegate.h"

@interface AsynchronousNetworkFetcher : NSObject
{
    id<AsynchronousNetworkFetcherDelegate> delegate;

    NSURL * url;
    NSURLConnection * connection;

    NSInteger contentLength;
    NSMutableData * data;
}

@property (nonatomic, assign) id<AsynchronousNetworkFetcherDelegate> delegate;
@property (nonatomic, readonly) NSURL * url;

+ (id)fetcherWithUrl:(NSURL *)url;
+ (id)fetcherWithUrl:(NSURL *)url
            delegate:(id<AsynchronousNetworkFetcherDelegate>)aDelegate;

- (id)initWithUrl:(NSURL *)url;
- (id)initWithUrl:(NSURL *)aUrl
         delegate:(id<AsynchronousNetworkFetcherDelegate>)aDelegate;

@end
