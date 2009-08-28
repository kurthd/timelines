//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrDataFetcher.h"
#import "NSDictionary+NonRetainedKeyAdditions.h"
#import "FlickrPhotoService.h"

@interface FlickrDataFetcher ()

- (OFFlickrAPIRequest *)newRequest;

- (NSInvocation *)delegateInvocationForSelector:(SEL)selector;

- (void)setSuccessInvocation:(NSInvocation *)invocation
                  forRequest:(OFFlickrAPIRequest *)request;
- (void)setFailureInvocation:(NSInvocation *)invocation
                  forRequest:(OFFlickrAPIRequest *)request;

- (NSInvocation *)successInvocationForRequest:(OFFlickrAPIRequest *)request;
- (NSInvocation *)failureInvocationForRequest:(OFFlickrAPIRequest *)request;

- (void)requestCompleted:(OFFlickrAPIRequest *)request;

@property (nonatomic, retain) NSMutableDictionary * successInvocations;
@property (nonatomic, retain) NSMutableDictionary * failureInvocations;

@property (nonatomic, retain) OFFlickrAPIContext * context;

@end

@implementation FlickrDataFetcher

@synthesize delegate;
@synthesize successInvocations, failureInvocations;
@synthesize context;
@synthesize token;

- (void)dealloc
{
    self.delegate = nil;

    self.successInvocations = nil;
    self.failureInvocations = nil;

    self.context = nil;
    self.token = nil;

    [super dealloc];
}

- (id)initWithDelegate:(id<FlickrDataFetcherDelegate>)aDelegate
{
    if (self = [super init]) {
        self.delegate = aDelegate;

        NSString * key = [FlickrPhotoService apiKey];
        NSString * secret = [FlickrPhotoService sharedSecret];

        context =
            [[OFFlickrAPIContext alloc] initWithAPIKey:key sharedSecret:secret];

        successInvocations = [[NSMutableDictionary alloc] init];
        failureInvocations = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)fetchTags:(NSString *)userId
{
    OFFlickrAPIRequest * request = [self newRequest];

    NSDictionary * args =
        [NSDictionary dictionaryWithObject:userId forKey:@"user_id"];
    [request callAPIMethodWithGET:@"flickr.tags.getListUser" arguments:args];

    SEL successSelector = @selector(dataFetcher:fetchedTags:);
    SEL failureSelector = @selector(dataFetcher:failedToFetchTags:);

    NSInvocation * successHandler =
        [self delegateInvocationForSelector:successSelector];
    [self setSuccessInvocation:successHandler forRequest:request];

    NSInvocation * failureHandler =
        [self delegateInvocationForSelector:failureSelector];
    [self setFailureInvocation:failureHandler forRequest:request];
}

#pragma mark OFFlickrAPIRequestDelegate implementation

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
    didCompleteWithResponse:(NSDictionary *)response
{
    NSInvocation * inv = [self successInvocationForRequest:request];
    [inv setArgument:&self atIndex:2];
    [inv setArgument:&response atIndex:3];

    [inv invoke];

    [self requestCompleted:request];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
        didFailWithError:(NSError *)error
{
    NSInvocation * inv = [self failureInvocationForRequest:request];
    [inv setArgument:&self atIndex:2];
    [inv setArgument:&error atIndex:3];

    [inv invoke];

    [self requestCompleted:request];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest
    imageUploadSentBytes:(NSUInteger)inSentBytes
              totalBytes:(NSUInteger)inTotalBytes
{
    NSLog(@"Uploaded %d of %d bytes.", inSentBytes, inTotalBytes);
}

#pragma mark Private implementation

- (OFFlickrAPIRequest *)newRequest
{
    OFFlickrAPIRequest * request =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
    [request setDelegate:self];

    return request;
}

- (NSInvocation *)delegateInvocationForSelector:(SEL)selector
{
    NSMethodSignature * sig =
        [(NSObject *) self.delegate methodSignatureForSelector:selector];
    NSInvocation * inv = [NSInvocation invocationWithMethodSignature:sig];

    [inv setTarget:self.delegate];
    [inv setSelector:selector];

    return inv;
}

- (void)setSuccessInvocation:(NSInvocation *)invocation
                  forRequest:(OFFlickrAPIRequest *)request
{
    [self.successInvocations setObject:invocation
                     forNonRetainedKey:request];
}

- (void)setFailureInvocation:(NSInvocation *)invocation
                  forRequest:(OFFlickrAPIRequest *)request
{
    [self.failureInvocations setObject:invocation
                     forNonRetainedKey:request];
}

- (NSInvocation *)successInvocationForRequest:(OFFlickrAPIRequest *)request
{
    return [self.successInvocations objectForNonRetainedKey:request];
}

- (NSInvocation *)failureInvocationForRequest:(OFFlickrAPIRequest *)request
{
    return [self.failureInvocations objectForNonRetainedKey:request];
}

- (void)requestCompleted:(OFFlickrAPIRequest *)request
{
    [self.successInvocations removeObjectForNonRetainedKey:request];
    [self.failureInvocations removeObjectForNonRetainedKey:request];

    [request autorelease];
}

#pragma mark Accessors

- (void)setToken:(NSString *)aToken
{
    if (token != aToken) {
        [token release];
        token = [aToken copy];

        [self.context setAuthToken:token];
    }
}

@end
