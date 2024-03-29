//
//  XAuthTwitterEngine.h
//  
//  Created by Aral Balkan on 28/02/2010.
//  Copyright 2010 Naklab. All rights reserved.
//
//  Based on SA_OAuthTwitterEngine Ben Gottlieb.
//
//  Some code and concepts taken from examples provided by 
//  Matt Gemmell, Chris Kimpton, and Isaiah Carew
//  See ReadMe for further attributions, copyrights and license info.
//

#import "MGTwitterHTTPURLConnection.h"

#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OAToken.h"

#import "XAuthTwitterEngine.h"

@interface XAuthTwitterEngine (private)

- (void) requestURL:(NSURL *) url token:(OAToken *)token onSuccess:(SEL)success onFail:(SEL)fail;

- (void) setRequestToken: (OAServiceTicket *) ticket withData: (NSData *) data;
- (void) setAccessToken: (OAServiceTicket *) ticket withData: (NSData *) data;

- (NSString *) extractUsernameFromHTTPBody:(NSString *)body;

// MGTwitterEngine impliments this
// include it here just so that we
// can use this private method
- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;

@end



@implementation XAuthTwitterEngine

@synthesize accessTokenURL = _accessTokenURL;
@synthesize consumerSecret = _consumerSecret, consumerKey = _consumerKey;
@synthesize accessToken = _accessToken;

- (void) dealloc {
	self.accessTokenURL = nil;
	
	[_accessToken release];
	[_consumer release];
	[super dealloc];
}


+ (XAuthTwitterEngine *) XAuthTwitterEngineWithDelegate: (NSObject *) delegate {
    return [[[XAuthTwitterEngine alloc] initXAuthWithDelegate: delegate] autorelease];
}


- (XAuthTwitterEngine *) initXAuthWithDelegate: (NSObject *) delegate {
    if (self = (id) [super initWithDelegate: delegate]) {
		self.accessTokenURL = [NSURL URLWithString: @"http://twitter.com/oauth/access_token"];
	}
    return self;
}

//=============================================================================================================================

#pragma mark OAuth Code
- (BOOL) OAuthSetup {
	return _consumer != nil;
}

- (OAConsumer *) consumer {
	if (_consumer) return _consumer;
	
	NSAssert(self.consumerKey.length > 0 && self.consumerSecret.length > 0, @"You must first set your Consumer Key and Consumer Secret properties. Visit http://twitter.com/oauth_clients/new to obtain these.");
	_consumer = [[OAConsumer alloc] initWithKey: self.consumerKey secret: self.consumerSecret];
	return _consumer;
}

- (BOOL) isAuthorized {	
	if (_accessToken.key && _accessToken.secret) return YES;
	
	//first, check for cached creds
	NSString *accessTokenString = [_delegate respondsToSelector: @selector(cachedTwitterXAuthAccessTokenStringForUsername:)] ? [(id) _delegate cachedTwitterXAuthAccessTokenStringForUsername: self.username] : @"";
	
	if (accessTokenString.length) {				
		[_accessToken release];
		_accessToken = [[OAToken alloc] initWithHTTPResponseBody: accessTokenString];
		[self setUsername: [self extractUsernameFromHTTPBody: accessTokenString] password: nil];
		if (_accessToken.key && _accessToken.secret) return YES;
	}
	
	[_accessToken release];										// no access token found.  create a new empty one
	_accessToken = [[OAToken alloc] initWithKey: nil secret: nil];
	return NO;
}


/*
//this is what we eventually want
- (void) requestAccessToken {
	[self requestURL: self.accessTokenURL token: _requestToken onSuccess: @selector(setAccessToken:withData:) onFail: @selector(outhTicketFailed:data:)];
}
*/


- (void) clearAccessToken {
	if ([_delegate respondsToSelector: @selector(storeCachedTwitterXAuthAccessTokenString:forUsername:)]) [(id) _delegate storeCachedTwitterXAuthAccessTokenString: @"" forUsername: self.username];
	[_accessToken release];
	_accessToken = nil;
	[_consumer release];
	_consumer = nil;
}

/*
- (void) setPin: (NSString *) pin {
	[_pin autorelease];
	_pin = [pin retain];
	
	_accessToken.pin = pin;
	_requestToken.pin = pin;
}
*/

#pragma mark -
#pragma mark xAuth 

//
// Attempts to retrieve an xAuthAccessToken for the passed username and password 
//
-(void)exchangeAccessTokenForUsername:(NSString *)username password:(NSString *)password
{
	//
	// Modified from http://github.com/norio-nomura/ntlniph/commit/5ce25d68916cd45254c7ff2ba9b91de4f324899a
	// Courtesy of Norio Nomura (@norio_nomura) via Steve Reynolds (@SteveReynolds)
	//
	// Carry out the xAuth, using the OAuthConsumer library directly.
	//
	NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer: self.consumer
																	  token:nil   // we don't have a Token yet
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil] ; // use the default method, HMAC-SHA1
	
	[request setHTTPMethod:@"POST"];
	[request setParameters:[NSArray arrayWithObjects:
							[OARequestParameter requestParameterWithName:@"x_auth_mode" value:@"client_auth"],
							[OARequestParameter requestParameterWithName:@"x_auth_username" value:username],
							[OARequestParameter requestParameterWithName:@"x_auth_password" value:password],
							nil]];
	
	OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
	[fetcher fetchDataWithRequest:request
						 delegate:self
				didFinishSelector:@selector(/*accessTokenTicket:didFinishWithData:*/setAccessToken:withData:)
				  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
	
	[request release];	
}

//=============================================================================================================================
#pragma mark Private OAuth methods
- (void) requestURL: (NSURL *) url token: (OAToken *) token onSuccess: (SEL) success onFail: (SEL) fail {
	
    OAMutableURLRequest				*request = [[[OAMutableURLRequest alloc] initWithURL: url consumer: self.consumer token:token realm:nil signatureProvider: nil] autorelease];
	if (!request) return;
	
    [request setHTTPMethod: @"POST"];
	
    OADataFetcher				*fetcher = [[[OADataFetcher alloc] init] autorelease];	
    [fetcher fetchDataWithRequest: request delegate: self didFinishSelector: success didFailSelector: fail];
}

//
//
- (void) accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *) error {
	if ([_delegate respondsToSelector: @selector(twitterXAuthConnectionDidFailWithError:)]) [(id) _delegate twitterXAuthConnectionDidFailWithError: error];	
}

//
// if the fetch fails this is what will happen
// you'll want to add your own error handling here.
//
/*
- (void) outhTicketFailed: (OAServiceTicket *) ticket data: (NSData *) data {
	if ([_delegate respondsToSelector: @selector(twitterOAuthConnectionFailedWithData:)]) [(id) _delegate twitterOAuthConnectionFailedWithData: data];
}
*/

//
// request token callback
// when twitter sends us a request token this callback will fire
// we can store the request token to be used later for generating
// the authentication URL
//
/*
- (void) setRequestToken: (OAServiceTicket *) ticket withData: (NSData *) data {
	if (!ticket.didSucceed || !data) return;
	
	NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if (!dataString) return;
	
	[_requestToken release];
	_requestToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
	
	if (self.pin.length) _requestToken.pin = self.pin;
}
*/

//
// access token callback
// when twitter sends us an access token this callback will fire
// we store it in our ivar as well as writing it to the keychain
//

- (void) setAccessToken: (OAServiceTicket *) ticket withData: (NSData *) data {
	if (!ticket.didSucceed || !data) return;
	
	NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if (!dataString) return;
		
	NSString *username = [self extractUsernameFromHTTPBody:dataString];

    if (!username) {  // jad: treat the data string as an error message
        NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:dataString, NSLocalizedDescriptionKey, nil];
        NSError * error = [NSError errorWithDomain:@"Twitter XAuth" code:-1 userInfo:userInfo];
        [self accessTokenTicket:ticket didFailWithError:error];
    } else if (username.length > 0) {
		[self setUsername: username password: nil];
		if ([_delegate respondsToSelector: @selector(storeCachedTwitterXAuthAccessTokenString:forUsername:)]) [(id) _delegate storeCachedTwitterXAuthAccessTokenString: dataString forUsername: username];
	}
	
	[_accessToken release];
	_accessToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
}


- (NSString *) extractUsernameFromHTTPBody: (NSString *) body {
	if (!body) return nil;
	
	NSArray					*tuples = [body componentsSeparatedByString: @"&"];
	if (tuples.count < 1) return nil;
	
	for (NSString *tuple in tuples) {
		NSArray *keyValueArray = [tuple componentsSeparatedByString: @"="];
		
		if (keyValueArray.count == 2) {
			NSString				*key = [keyValueArray objectAtIndex: 0];
			NSString				*value = [keyValueArray objectAtIndex: 1];
			
			if ([key isEqualToString:@"screen_name"]) return value;
		}
	}
	
	return nil;
}

//=============================================================================================================================
#pragma mark MGTwitterEngine Changes
//These are all verbatim from Isaiah Carew and Chris Kimpton's code

// --------------------------------------------------------------------------------
//
// these method overrides were created from the work that Chris Kimpton
// did.  i've chosen to subclass instead of directly modifying the
// MGTwitterEngine as it makes integrating MGTwitterEngine changes a bit
// easier.
// 
// the code here is largely unchanged from chris's implimentation.
// i've tried to highlight the areas that differ from 
// the base class implimentation.
//
// --------------------------------------------------------------------------------

#define SET_AUTHORIZATION_IN_HEADER 1

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params 
                                body:(NSString *)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType
{
    NSString *fullPath = path;
	
	// --------------------------------------------------------------------------------
	// modificaiton from the base clase
	// the base class appends parameters here
	// --------------------------------------------------------------------------------
	//    if (params) {
	//        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
	//    }
	// --------------------------------------------------------------------------------
	
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", 
                           (_secureConnection) ? @"https" : @"http",
                           _APIDomain, fullPath];
    NSURL *finalURL = [NSURL URLWithString:urlString];
    if (!finalURL) {
        return nil;
    }
	
	// --------------------------------------------------------------------------------
	// modificaiton from the base clase
	// the base class creates a regular url request
	// we're going to create an oauth url request
	// --------------------------------------------------------------------------------
	//    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:finalURL 
	//                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
	//                                                          timeoutInterval:URL_REQUEST_TIMEOUT];
	// --------------------------------------------------------------------------------
	NSLog(@"here %@", _accessToken);
	OAMutableURLRequest *theRequest = [[[OAMutableURLRequest alloc] initWithURL:finalURL
																	   consumer:self.consumer 
																		  token:_accessToken 
																		  realm: nil
															  signatureProvider:nil] autorelease];
    if (method) {
        [theRequest setHTTPMethod:method];
    }
    [theRequest setHTTPShouldHandleCookies:NO];
    
    // Set headers for client information, for tracking purposes at Twitter.
    [theRequest setValue:_clientName    forHTTPHeaderField:@"X-Twitter-Client"];
    [theRequest setValue:_clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
    [theRequest setValue:_clientURL     forHTTPHeaderField:@"X-Twitter-Client-URL"];
    
    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:@"POST"]);
    if (isPOST) {
        // Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
        NSString *finalBody = @"";
		if (body) {
			finalBody = [finalBody stringByAppendingString:body];
		}
        if (_clientSourceToken) {
            finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@", 
                                                            (body) ? @"&" : @"?" , 
                                                            _clientSourceToken]];
        }
        
        if (finalBody) {
            [theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
	
	// --------------------------------------------------------------------------------
	// modificaiton from the base clase
	// our version "prepares" the oauth url request
	// --------------------------------------------------------------------------------
	[theRequest prepare];
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:requestType 
                                                        responseType:responseType];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
    
    return [connection identifier];
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	
	// --------------------------------------------------------------------------------
	// modificaiton from the base clase
	// instead of answering the authentication challenge, we just ignore it.
	// seems a bit odd to me, but this is what Chris Kimpton did and it seems to work,
	// so i'm rolling with it.
	// --------------------------------------------------------------------------------
	//	if ([challenge previousFailureCount] == 0 && ![challenge proposedCredential]) {
	//		NSURLCredential *credential = [NSURLCredential credentialWithUser:_username password:_password 
	//															  persistence:NSURLCredentialPersistenceForSession];
	//		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	//	} else {
	//		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	//	}
	// --------------------------------------------------------------------------------
	
	[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	return;
	
}

@end

