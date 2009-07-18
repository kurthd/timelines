//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "CommonTwitterServicePhotoSource.h"
#import "AsynchronousNetworkFetcher.h"
#import "RegexKitLite.h"

@interface CommonTwitterServicePhotoSource ()

- (void)requestImageFromHtml:(NSString *)html withUrl:(NSString *)urlAsString;

@end

@implementation CommonTwitterServicePhotoSource

@synthesize delegate;

- (void)dealloc
{
    [urlMapping release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
        urlMapping = [[NSMutableDictionary dictionary] retain];

    return self;
}

#pragma mark PhotoSource implementation

- (void)fetchImageWithUrl:(NSString *)url
{
    NSURL * imageUrl = [NSURL URLWithString:url];
    [AsynchronousNetworkFetcher fetcherWithUrl:imageUrl delegate:self];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * urlAsString = [url absoluteString];

    NSLog(@"Url as string: %@", urlAsString);
    static NSString * imageRegex =
        @".*\\.png.*|.*\\.jpg.*|.*\\.gif.*|.*\\.tiff.*";
    if (![urlAsString isMatchedByRegex:imageRegex]) {
        NSString * html =
            [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]
            autorelease];
        [self requestImageFromHtml:html withUrl:urlAsString];
    } else {
        UIImage * image = [UIImage imageWithData:data];
        NSString * originalUrl = [urlMapping objectForKey:urlAsString];
        originalUrl = originalUrl ? originalUrl : urlAsString;
        [delegate fetchedImage:image withUrl:originalUrl];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{}

#pragma mark CommonTwitterServicePhotoSource implementation

- (void)requestImageFromHtml:(NSString *)html withUrl:(NSString *)url
{
    NSString * regex = nil;
    NSString * removeString = nil;

    if ([url isMatchedByRegex:@"^http://twitpic.com/"]) {
        regex = @"http:\\/\\/s3\\.amazonaws\\.com\\/twitpic\\/photo.*\"";
        removeString = @"\"";
    } else if ([url isMatchedByRegex:@"^http://yfrog.com/"]) {
        regex =
            @"http:\\\\\\/\\\\\\/img\\d+\\.imageshack\\.\\w+\\\\\\/img\\d+\\\\\\/\\d+\\\\\\/\\w+\\.\\w+\\\\n";
        removeString = @"\\\\n|\\\\";
    } else if ([url isMatchedByRegex:@"^http://tinypic.com/"]) {
        regex =
            @"http:\\/\\/[a-zA-Z0-9]+\\.tinypic\\.com\\/[a-zA-Z0-9]+\\.\\w+\"";
        removeString = @"\"";
    } else if ([url isMatchedByRegex:@"^http://twitgoo.com/"]) {
        regex =
            @"http:\\/\\/[a-zA-Z0-9]+\\.tinypic\\.com\\/[a-zA-Z0-9]+\\.\\w+\"";
        removeString = @"\"";
    } else if ([url isMatchedByRegex:@"^http://mobypicture.com/"]) {
        regex =
            @"http:\\/\\/www\\.mobypicture\\.com\\/images\\/user\\/[a-zA-Z0-9_]+\\.\\w+\"";
        removeString = @"\"";
    }

    NSString * imageUrl = [html stringByMatching:regex];
    imageUrl =
        [imageUrl stringByReplacingOccurrencesOfRegex:removeString
        withString:@""];
    NSLog(@"Parsed image '%@' from html; sending request...", imageUrl);

    if (imageUrl && ![imageUrl isEqual:@""]) {
        [urlMapping setObject:url forKey:imageUrl];
    
        [self fetchImageWithUrl:imageUrl];
    } else
        [delegate unableToFindImageForUrl:url];
}

@end
