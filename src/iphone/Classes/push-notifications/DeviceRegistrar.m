//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeviceRegistrar.h"

@interface DeviceRegistrar ()

@property (nonatomic, copy) NSString * urlString;
@property (nonatomic, copy) NSData * deviceToken;

@end

@implementation DeviceRegistrar

@synthesize delegate;
@synthesize urlString;
@synthesize deviceToken;

- (void)dealloc
{
    self.delegate = nil;
    self.urlString = nil;
    self.deviceToken = nil;
    [super dealloc];
}

- (id)initWithDomain:(NSString *)aDomain
{
    if (self = [super init])
        // device contacts a url of the form:
        //  https://sandbox.twitch.highorderbit.com/device/register
        self.urlString =
        //[NSString stringWithFormat:@"https://%@/device/register", aDomain];
        [NSString stringWithFormat:@"http://%@/device/register", aDomain];

    return self;
}

- (void)sendProviderDeviceToken:(NSData *)devToken args:(NSDictionary *)args
{
    self.deviceToken = devToken;

    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSMutableString * body =
        [NSMutableString stringWithFormat:@"devicetoken=%@", devToken];
    [body replaceOccurrencesOfString:@"<" withString:@""
                             options:0 range:NSMakeRange(0, body.length)];
    [body replaceOccurrencesOfString:@">" withString:@""
                             options:0 range:NSMakeRange(0, body.length)];
    [body replaceOccurrencesOfString:@" " withString:@""
                             options:0 range:NSMakeRange(0, body.length)];

    for (id key in args)
        [body appendFormat:@"&%@=%@", key, [args objectForKey:key]];

    NSString * encodedBody =
        [body stringByAddingPercentEscapesUsingEncoding:encoding];

    NSURL * url = [NSURL URLWithString:self.urlString];
    NSMutableURLRequest * req =
        [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[encodedBody dataUsingEncoding:encoding]];

    NSURLConnection * conn = [[NSURLConnection alloc] initWithRequest:req
                                                             delegate:self
                                                     startImmediately:YES];

    NSLog(@"Started connection: '%@'.", conn);
}

#pragma mark NSURLConnectionDelegate implementation

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"Received data: '%@'.",
        [[[NSString alloc] initWithData:data encoding:4] autorelease]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    NSLog(@"Connection did finish loading: '%@'.", conn);

    [delegate registeredDeviceWithToken:self.deviceToken];
    self.deviceToken = nil;
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    NSLog(@"Connection '%@' did fail with error: '%@'.", conn, error);

    [delegate failedToRegisterDeviceWithToken:self.deviceToken error:error];
    self.deviceToken = nil;
}

@end
