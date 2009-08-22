//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "Geocoder.h"
#import "AsynchronousNetworkFetcher.h"
#import "InfoPlistConfigReader.h"
#import "RegexKitLite.h"

@interface Geocoder ()

- (NSURL *)request;

@end

@implementation Geocoder

@synthesize delegate, querying;

- (void)dealloc
{
    [query release];
    [super dealloc];
}

- (id)initWithQuery:(NSString *)aQuery
{
    if (self = [super init]) {
        query = [aQuery copy];
    }

    return self;
}

- (void)start
{
    NSLog(@"Sending geocoding request '%@'", query);
    [AsynchronousNetworkFetcher fetcherWithUrl:[self request] delegate:self];
    NSLog(@"URL: %@", [[self request] absoluteString]);
    querying = YES;
}

- (void)cancel
{
    canceled = YES;
    querying = NO;
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    if (!canceled) {
        querying = NO;
        NSString * response =
            [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]
            autorelease];
        NSLog(@"Received geocode response");
        NSString * coordinatesAsString =
            [response stringByMatching:
            @"\"coordinates\":\\s*\\[\\s*([-\\d\\.]+\\s*,\\s*[-\\d\\.]+)\\s*,\\s*[-\\d\\.]+\\s*\\]" capture:1];
        NSLog(@"Coordinates as string: %@", coordinatesAsString);
        NSArray * components =
            [coordinatesAsString componentsSeparatedByRegex:@"\\s*,\\s*"];
        if ([components count] == 2) {
            CLLocationCoordinate2D coord;
            coord.latitude = [[components objectAtIndex:1] doubleValue];
            coord.longitude = [[components objectAtIndex:0] doubleValue];
            [delegate geocoder:self didFindCoordinate:coord];
        } else
            [delegate unableToFindCoordinatesWithGeocoder:self];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    if (!canceled) {
        querying = NO;
        [delegate geocoder:self didFailWithError:error];
    }
}

- (NSURL *)request
{
    NSString * apiKey =
        [[InfoPlistConfigReader reader] valueForKey:@"GoogleMapsApiKey"];
    NSString * formattedQuery =
        [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString * urlString =
        [NSString stringWithFormat:
        @"http://maps.google.com/maps/geo?q=%@=&output=json&oe=utf8&sensor=true_or_false&key=%@",
        formattedQuery, apiKey];
    
    return [NSURL URLWithString:urlString];
}

@end
