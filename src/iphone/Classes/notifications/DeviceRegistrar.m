//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeviceRegistrar.h"

@implementation DeviceRegistrar

- (id)init
{
    return self = [super init];
}

- (void)sendProviderDeviceToken:(NSData *)devToken
{
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString * body = [NSString stringWithFormat:@"devicetoken=%@", devToken];
    body = [body stringByReplacingOccurrencesOfString:@"<" withString:@""];
    body = [body stringByReplacingOccurrencesOfString:@">" withString:@""];
    body = [body stringByAddingPercentEscapesUsingEncoding:encoding];
    NSLog(@"Sending body: '%@'.", body);

    NSURL * url =
        [NSURL URLWithString:@"http://megatron.local:3000/register_device"];
    NSMutableURLRequest * req =
        [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[body dataUsingEncoding:encoding]];

    NSURLConnection * conn = [[NSURLConnection alloc] initWithRequest:req
                                                             delegate:self
                                                     startImmediately:YES];

    NSLog(@"Started connection: '%@'.", conn);
}

#pragma mark NSURLConnectionDelegate implementation

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"Received data: '%@'.",
        [[[NSString alloc] initWithData:data encoding:4] autorelease]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    NSLog(@"Connection did finish loading: '%@'.", conn);
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    NSLog(@"Connection '%@' did fail with error: '%@'.", conn, error);
}

@end
