//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "BitlyUrlShorteningService.h"
#import "InfoPlistConfigReader.h"
#import "NSString+HtmlEncodingAdditions.h"
#import "NSError+InstantiationAdditions.h"
#import "JSON.h"

@interface BitlyUrlShorteningService ()

@property (nonatomic, copy) NSString * version;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * apiKey;

@end

@implementation BitlyUrlShorteningService

@synthesize delegate;
@synthesize version, username, apiKey;

- (void)dealloc
{
    self.delegate = nil;

    self.version = nil;
    self.username = nil;
    self.apiKey = nil;

    [super dealloc];
}

- (id)init
{
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<BitlyUrlShorteningServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.delegate = aDelegate;

        self.version =
            [[InfoPlistConfigReader reader] valueForKey:@"BitlyVersion"];
        self.username =
            [[InfoPlistConfigReader reader] valueForKey:@"BitlyUsername"];
        self.apiKey =
            [[InfoPlistConfigReader reader] valueForKey:@"BitlyApiKey"];
    }

    return self;
}

- (void)shortenUrl:(NSString *)url
{
    // the link needs to be encoded because it could contain query parameters
    static NSString * allowed = @":@/?&";
    NSString * encodedUrl =
        [url urlEncodedStringWithEscapedAllowedCharacters:allowed];

    NSString * urlAsString =
        [NSString stringWithFormat:
        @"http://api.bit.ly/shorten?version=%@&longUrl=%@&login=%@&apiKey=%@",
        version, encodedUrl, username, apiKey];
    NSLog(@"Link shortening request: %@", urlAsString);

    NSURL * theUrl = [NSURL URLWithString:urlAsString];
    [AsynchronousNetworkFetcher fetcherWithUrl:theUrl delegate:self];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * jsonString =
        [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
        autorelease];
    NSDictionary * json = [jsonString JSONValue];
    NSLog(@"Have json: %@", json);
    if (!json) {
        NSString * message = NSLocalizedString(@"bitly.shortening.failed", @"");
        NSError * error = [NSError errorWithLocalizedDescription:message];
        [self fetcher:fetcher failedToReceiveDataFromUrl:url error:error];
    } else {
        NSDictionary * results = [json objectForKey:@"results"];
        // there should be one key here, which is the long URL we sent
        NSString * longUrl = [[results allKeys] objectAtIndex:0];
        NSString * shortUrl =
            [[results objectForKey:longUrl] objectForKey:@"shortUrl"];

        NSLog(@"Long URL: '%@' => '%@'", longUrl, shortUrl);

        [self.delegate shorteningService:self
                       didShortenLongUrl:longUrl
                              toShortUrl:shortUrl];
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
}

@end

@implementation BitlyUrlShorteningService (UrlShortening)

- (void)shortenUrls:(NSSet *)urls
{
    for (id url in urls)
        [self shortenUrl:url];
}

@end
