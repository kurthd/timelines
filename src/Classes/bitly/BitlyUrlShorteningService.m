//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "BitlyUrlShorteningService.h"
#import "InfoPlistConfigReader.h"
#import "NSString+HtmlEncodingAdditions.h"
#import "NSError+InstantiationAdditions.h"
#import "NSDictionary+NonRetainedKeyAdditions.h"
#import "TwitbitShared.h"
#import "JSON.h"

@interface BitlyUrlShorteningService ()

@property (nonatomic, copy) NSString * version;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * apiKey;
@property (nonatomic, copy) NSString * defaultUsername;
@property (nonatomic, copy) NSString * defaultApiKey;

@property (nonatomic, retain) NSMutableDictionary * requests;

@end

@implementation BitlyUrlShorteningService

@synthesize delegate;
@synthesize version, username, apiKey, defaultUsername, defaultApiKey;
@synthesize requests;

- (void)dealloc
{
    self.delegate = nil;

    self.version = nil;
    self.username = nil;
    self.apiKey = nil;
    self.defaultUsername = nil;
    self.defaultApiKey = nil;

    self.requests = nil;

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
        self.defaultUsername =
            [[InfoPlistConfigReader reader] valueForKey:@"BitlyUsername"];
        self.defaultApiKey =
            [[InfoPlistConfigReader reader] valueForKey:@"BitlyApiKey"];

        self.requests = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)setUsername:(NSString *)aUsername apiKey:(NSString *)anApiKey
{
    self.username = aUsername;
    self.apiKey = anApiKey;
}

- (void)shortenUrl:(NSString *)url
{
    // the link needs to be encoded because it could contain query parameters
    static NSString * allowed = @":@/?&";
    NSString * encodedUrl =
        [url urlEncodedStringWithEscapedAllowedCharacters:allowed];

    NSMutableString * urlAsString =
        [NSMutableString stringWithFormat:
        @"http://api.j.mp/shorten?version=%@&longUrl=%@", version, encodedUrl];
    if (self.username && self.apiKey)
        [urlAsString appendFormat:@"&login=%@&apiKey=%@", self.username,
            self.apiKey];
    else
        [urlAsString appendFormat:@"&login=%@&apiKey=%@", self.defaultUsername,
            self.defaultApiKey];

    NSLog(@"Link shortening request: %@", urlAsString);

    NSURL * theUrl = [NSURL URLWithString:urlAsString];
    AsynchronousNetworkFetcher * fetcher =
        [AsynchronousNetworkFetcher fetcherWithUrl:theUrl delegate:self];

    [self.requests setObject:url forNonRetainedKey:fetcher];
}

#pragma mark AsynchronousNetworkFetcherDelegate implementation

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    didReceiveData:(NSData *)data fromUrl:(NSURL *)url
{
    NSString * jsonString =
        [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
        autorelease];
    NSError * error = nil;
    NSDictionary * json = [jsonString JSONValueOrError:&error];
    NSLog(@"Received response from bit.ly: %@, error: %@", json, error);
    if (!json) {
        if (!error) {
            NSString * message = LS(@"bitly.shortening.failed.unknown");
            error = [NSError errorWithLocalizedDescription:message];
        }
        [self fetcher:fetcher failedToReceiveDataFromUrl:url error:error];
    } else {
        NSString * errorMessage = [json objectForKey:@"errorMessage"];
        if (errorMessage && errorMessage.length > 0) {
            error = [NSError errorWithLocalizedDescription:errorMessage];
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

            [self.requests removeObjectForNonRetainedKey:fetcher];
        }
    }
}

- (void)fetcher:(AsynchronousNetworkFetcher *)fetcher
    failedToReceiveDataFromUrl:(NSURL *)url error:(NSError *)error
{
    NSLog(@"Fetcher failed: '%@'", error);

    NSString * longUrl = [self.requests objectForNonRetainedKey:fetcher];
    [self.delegate shorteningService:self
                 didFailToShortenUrl:longUrl
                               error:error];

    [self.requests removeObjectForNonRetainedKey:fetcher];
}

@end

@implementation BitlyUrlShorteningService (UrlShortening)

- (void)shortenUrls:(NSSet *)urls
{
    for (id url in urls)
        [self shortenUrl:url];
}

@end
