//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousNetworkFetcher.h"

@protocol BitlyUrlShorteningServiceDelegate;

@interface BitlyUrlShorteningService :
    NSObject <AsynchronousNetworkFetcherDelegate>
{
    id<BitlyUrlShorteningServiceDelegate> delegate;

    NSString * version;
    NSString * username;
    NSString * apiKey;
    NSString * defaultUsername;
    NSString * defaultApiKey;

    NSMutableDictionary * requests;
}

@property (nonatomic, assign) id<BitlyUrlShorteningServiceDelegate> delegate;

- (id)init;
- (id)initWithDelegate:(id<BitlyUrlShorteningServiceDelegate>)aDelegate;

- (void)setUsername:(NSString *)username apiKey:(NSString *)apiKey;
- (void)shortenUrl:(NSString *)url;

@end

@interface BitlyUrlShorteningService (UrlShortening)

- (void)shortenUrls:(NSSet *)urls;

@end


@protocol BitlyUrlShorteningServiceDelegate

- (void)shorteningService:(BitlyUrlShorteningService *)service
        didShortenLongUrl:(NSString *)longUrl
               toShortUrl:(NSString *)shortUrl;

- (void)shorteningService:(BitlyUrlShorteningService *)service
      didFailToShortenUrl:(NSString *)longUrl
                    error:(NSError *)error;


@end
