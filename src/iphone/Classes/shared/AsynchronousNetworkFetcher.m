//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AsynchronousNetworkFetcher.h"

@implementation AsynchronousNetworkFetcher

@synthesize delegate, url;

+ (id)fetcherWithUrl:(NSURL *)url
{
    return [[[[self class] alloc] initWithUrl:url] autorelease];
}

+ (id)fetcherWithUrl:(NSURL *)url
            delegate:(id<AsynchronousNetworkFetcherDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithUrl:url delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    [connection release];
    [url release];
    [data release];
    [super dealloc];
}

- (id)initWithUrl:(NSURL *)aUrl
{
    return [self initWithUrl:url delegate:nil];
}

- (id)initWithUrl:(NSURL *)aUrl
         delegate:(id<AsynchronousNetworkFetcherDelegate>)aDelegate
{
    if (self = [super init]) {
        url = [aUrl retain];
        NSURLRequest * req = [NSURLRequest requestWithURL:url];
        connection = [[NSURLConnection alloc] initWithRequest:req
                                                     delegate:self
                                             startImmediately:YES];
    }

    return self;
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)fragment
{
    [data appendData:fragment];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    SEL sel = @selector(fetcher:didReceiveData:fromUrl:);
    if ([delegate respondsToSelector:sel])
        [delegate fetcher:self didReceiveData:data fromUrl:url];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    SEL sel = @selector(fetcher:failedToReceiveDataFromUrl:error:);
    if ([delegate respondsToSelector:sel])
        [delegate fetcher:self failedToReceiveDataFromUrl:url error:error];
}

@end