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
        @"\\.png(\\?.*)?$|\\.jpg(\\?.*)?$|\\.jpeg(\\?.*)?$|\\.gif(\\?.*)?$|"
         "\\.tif(\\?.*)?$|\\.tiff(\\?.*)?$|\\.bmp(\\?.*)?$|\\.ico(\\?.*)?$";

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
    didReceiveSomeData:(double)percentComplete
{
    [delegate progressOfImageFetch:percentComplete];
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    NSLog(@"Failed to load image from URL: '%@': %@.", url, error);
    [delegate failedToFetchImageWithUrl:[url absoluteString] error:error];
}

#pragma mark CommonTwitterServicePhotoSource implementation

- (void)requestImageFromHtml:(NSString *)html withUrl:(NSString *)url
{
    NSString * imageUrl = [[self class] photoUrlFromPageHtml:html url:url];

    if (imageUrl && ![imageUrl isEqual:@""]) {
        [urlMapping setObject:url forKey:imageUrl];
    
        [self fetchImageWithUrl:imageUrl];
    } else
        [delegate unableToFindImageForUrl:url];
}

+ (NSString *)photoUrlFromPageHtml:(NSString *)html url:(NSString *)url
{
    NSString * regex = nil;
    NSInteger capture = 0;

    if ([url isMatchedByRegex:@"^http://twitpic.com/"]) {
        NSLog(@"Matching twitpic");
        NSLog(@"HTML: %@", html);
        // extract the 'src' attribute from the main img tag:
        // <img class="photo"
        //      id="photo-display"
        //      src="http://s3.amazonaws.com/twitpic/photos/large/...">
        regex =
            @"<img class=\"photo\"\\s+"
                   "id=\"photo-display\"\\s+"
                   "src=\"(.*?)\".*?>";
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://.*\\.?yfrog.com/"]) {
        // yfrog's main img tag uses an absolute URL without the domain,
        // e.g. "/img14/7946/ot4.png". We want to avoid one query for the
        // image path and another for the image domain. This is
        // the only place in the HTML where the full url lives. Example:
        // <link type="application/rss+xml"
        //       href="http://img14.yfrog.com/img14/7946/ot4.png.comments.xml"
        //       title="RSS"
        //       rel="alternate"/>
        regex =
            @"<link\\s+type=\"application/rss\\+xml\"\\s+"
                      "href=\"(.*)\\.comments\\.xml\"\\s+"
                      "title=\"RSS\"\\s+"
                      "rel=\"alternate\".*?>";
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://tinypic.com/"]) {
        // extract the 'src' attribute from the main img tag:
        //   <img src="http://i26.tinypic.com/28iudy9.jpg"
        //   title="Click for a larger view"
        //   id="imgElement"
        //   alt=""/>
        regex =
            @"<img\\s+src=\"(.*?)\"\\s+"
                     "title=\".*?\"\\s+"      // ignore the title
                     "id=\"imgElement\"\\s+"  // rely on the unique img id
                     "alt=\".*?\".*?>";     // ignore the alt tag
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://twitgoo.com/"]) {
        // extract the 'src' attribute from the main img tag:
        //  <img id="fullsize"
        //       src="http://i28.tinypic.com/2q15snq.jpg"
        //       alt="My brother and my niece." /> 
        regex =
            @"<img\\s+id=\"fullsize\"\\s+"
                     "src=\"(.*?)\"\\s+"
                     "alt=\".*?\".*?>";
        capture = 1;
    } else if ([url isMatchedByRegex:@"^http://mobypicture.com/"]) {
        // extract from the main image 'src' attribute:
        // <img class="imageLinkBorder"
        //      src="http://img.mobypicture.com/whatever.jpg"
        //      id="main_picture"
        //      alt="Whatever" />
        regex =
            @"<img\\s+class=\".*?\"\\s+"
                     "src=\"(.*?)\"\\s+"
                     "id=\"main_picture\"\\s+"
                     "alt=\".*?\".*?>";
        capture = 1;
    }

    NSString * imageUrl = [html stringByMatching:regex capture:capture];
    NSLog(@"Parsed image '%@' from html", imageUrl);

    return imageUrl;
}

@end
