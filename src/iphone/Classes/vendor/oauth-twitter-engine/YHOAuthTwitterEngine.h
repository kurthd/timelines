//
//  YHTwitter.h
//
//  Created by Isaiah Carew on 24 June 2009.
//  Copyright 2009 YourHead Software.
//
//  Some code and concepts taken from examples provided by 
//  Matt Gemmell and Chris Kimpton
//  See ReadMe for further attributions, copyrights and license info.
//

#import "MGTwitterEngine.h"

@class OAToken;
@class OAConsumer;
@class OADataFetcher;

@interface YHOAuthTwitterEngine : MGTwitterEngine {
	
	OAConsumer	*_consumer;
	OAToken		*_requestToken;
	OAToken		*_accessToken;
    OADataFetcher     *_fetcher;
	
}

+ (YHOAuthTwitterEngine *)oAuthTwitterEngineWithDelegate:(NSObject *)theDelegate;
- (YHOAuthTwitterEngine *)initOAuthWithDelegate:(NSObject *)newDelegate;

//- (BOOL)isAuthorized;
- (NSURLRequest *)authorizeURL;
- (void)requestAccessToken:(NSString *)pin;
- (void)requestRequestToken;
- (void)clearAccessToken;

@property (nonatomic, retain)	OAConsumer	*consumer;
@property (nonatomic, retain)	OAToken		*requestToken;
@property (nonatomic, retain)	OAToken		*accessToken;
@property (nonatomic, retain) OADataFetcher * fetcher;

@end


@protocol YHOAuthTwitterEngineDelegate 

- (void)receivedRequestToken:(id)sender;
- (void)receivedAccessToken:(id)sender;

@end
