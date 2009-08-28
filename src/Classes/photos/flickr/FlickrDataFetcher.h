//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjectiveFlickr.h"

@class FlickrDataFetcher;
@class OFFlickrAPIContext;

@protocol FlickrDataFetcherDelegate

- (void)dataFetcher:(FlickrDataFetcher *)fetcher
        fetchedTags:(NSDictionary *)tags;
- (void)dataFetcher:(FlickrDataFetcher *)fetcher
  failedToFetchTags:(NSError *)error;

@end

@interface FlickrDataFetcher : NSObject <OFFlickrAPIRequestDelegate>
{
    id<FlickrDataFetcherDelegate> delegate;

    NSMutableDictionary * successInvocations;
    NSMutableDictionary * failureInvocations;

    OFFlickrAPIContext * context;
    NSString * token;
}

@property (nonatomic, assign) id<FlickrDataFetcherDelegate> delegate;
@property (nonatomic, copy) NSString * token;

- (id)initWithDelegate:(id<FlickrDataFetcherDelegate>)aDelegate;

- (void)fetchTags:(NSString *)userId;

@end
