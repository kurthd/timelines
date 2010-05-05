//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AsynchronousNetworkFetcher.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

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
    [url release];
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
        data = [[NSMutableData alloc] init];
        NSURLRequest * req = [NSURLRequest requestWithURL:url];
        connection = [[NSURLConnection alloc] initWithRequest:req
                                                     delegate:self
                                             startImmediately:YES];
        self.delegate = aDelegate;

        // HACK
        // [[UIApplication sharedApplication] networkActivityIsStarting];

        // Bit of a hack, but make sure we are retained while the request is
        // outstanding
        [self retain];
    }

    return self;
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)conn
    didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSDictionary * headers = [response allHeaderFields];
    NSString * contentLengthString = [headers objectForKey:@"Content-Length"];
    contentLength =
        contentLengthString ? [contentLengthString integerValue] : -1;

    [data setLength:0];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)fragment
{
    [data appendData:fragment];

    if (contentLength != -1) {
        double percentComplete =
            (double) [data length] / (double) contentLength;
        SEL sel = @selector(fetcher:didReceiveSomeData:);
        if (delegate && [delegate respondsToSelector:sel])
            [delegate fetcher:self didReceiveSomeData:percentComplete];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    SEL sel = @selector(fetcher:didReceiveData:fromUrl:);
    if (delegate && [delegate respondsToSelector:sel])
        [delegate fetcher:self didReceiveData:data fromUrl:url];

    // HACK
    // [[UIApplication sharedApplication] networkActivityDidFinish];

    [connection release];
    [data release];
    [self release];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    SEL sel = @selector(fetcher:failedToReceiveDataFromUrl:error:);
    if ([delegate respondsToSelector:sel])
        [delegate fetcher:self failedToReceiveDataFromUrl:url error:error];

    // HACK
    // [[UIApplication sharedApplication] networkActivityDidFinish];

    [connection release];
    [data release];
    [self release];
}

@end
