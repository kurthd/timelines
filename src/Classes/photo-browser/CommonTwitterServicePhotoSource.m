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
        @".*\\.png.*|.*\\.jpg.*|.*\\.jpeg.*|.*\\.gif.*|.*\\.tif.*|.*\\.bmp.*";

    RKLRegexOptions options = RKLCaseless;
    NSRange range = NSMakeRange(0, urlAsString.length);
    NSError * error = 0;
    BOOL matches =
        [urlAsString
        isMatchedByRegex:imageRegex options:options inRange:range error:&error];
    if (error)
        NSLog(@"Error matching '%@' against '%@': %@.", urlAsString, imageRegex,
            error);

    if (error || !matches) {
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
    NSInteger capture = 0;

    if ([url isMatchedByRegex:@"^http://twitpic.com/"]) {
        // extract the 'src' attribute from a tag that looks like:
        //   <img id="photo-display"
        //        class="photo-large"
        //        src="http://web2.twitpic.com/..."
        //        alt="my twitpic">

        regex =
            @"<img id=\"photo-display\" class=\"photo-large\" src=\"(.*?)\"";
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://yfrog.com/"]) {
        // extract the 'href' attribute from:
        // <link type="application/rss+xml"
        //       href="http://img14.yfrog.com/img14/7946/ot4.png.comments.xml"
        //       title="RSS"
        //       rel="alternate"/>

        regex =
            @"<link\\s+type=\"application/rss\\+xml\"\\s+"
                      "href=\"(.*)\\.comments\\.xml\"\\s+"
                      "title=\"RSS\"\\s+"
                      "rel=\"alternate\"\\s*/>";
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://tinypic.com/"]) {
        // extract the 'src' attribute from an img tag:
        //   <img src="http://i26.tinypic.com/28iudy9.jpg"
        //   title="Click for a larger view"
        //   id="imgElement"
        //   alt=""/>
        regex =
            @"<img src=\"(.*?)\"\\s+"
                  "title=\".*?\"\\s+"      // ignore the title
                  "id=\"imgElement\"\\s+"  // rely on the unique img id
                  "alt=\".*?\"\\s*/>";     // ignore the alt tag
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://twitgoo.com/"]) {
        regex =
            @"(http:\\/\\/[a-zA-Z0-9]+\\.tinypic\\.com\\/[a-zA-Z0-9]+\\.\\w+\")";
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://mobypicture.com/"]) {
        regex =
            @"(http:\\/\\/www\\.mobypicture\\.com\\/images\\/user\\/[a-zA-Z0-9_]+\\.\\w+\")";
        capture = 1;
    }

    NSString * imageUrl = [html stringByMatching:regex capture:capture];
    NSLog(@"Parsed image '%@' from html; sending request...", imageUrl);

    if (imageUrl && ![imageUrl isEqual:@""]) {
        [urlMapping setObject:url forKey:imageUrl];
    
        [self fetchImageWithUrl:imageUrl];
    } else
        [delegate unableToFindImageForUrl:url];
}

@end
