//
//  MGTwitterEngine.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngine.h"
#import "MGTwitterHTTPURLConnection.h"

#import "NSData+Base64.h"

#define USE_LIBXML 0

#if JSON_AVAILABLE || YAJL_AVAILABLE
	#define API_FORMAT @"json"
#endif

#if JSON_AVAILABLE

    #import "MGTwitterJSONParser.h"

#elif YAJL_AVAILABLE
	#import "MGTwitterStatusesYAJLParser.h"
	#import "MGTwitterMessagesYAJLParser.h"
	#import "MGTwitterUsersYAJLParser.h"
	#import "MGTwitterMiscYAJLParser.h"
	#import "MGTwitterSearchYAJLParser.h"
#else
	#define API_FORMAT @"xml"

	#if USE_LIBXML
		#import "MGTwitterStatusesLibXMLParser.h"
		#import "MGTwitterMessagesLibXMLParser.h"
		#import "MGTwitterUsersLibXMLParser.h"
		#import "MGTwitterMiscLibXMLParser.h"
	#else
		#import "MGTwitterStatusesParser.h"
		#import "MGTwitterUsersParser.h"
		#import "MGTwitterMessagesParser.h"
		#import "MGTwitterMiscParser.h"
	#endif
#endif

#define TWITTER_DOMAIN_UNVERSIONED       @"twitter.com"
#define TWITTER_DOMAIN_VERSIONED          @"api.twitter.com"
#define TWITTER_API_VERSION               @"1"
#if JSON_AVAILABLE || YAJL_AVAILABLE
	#define TWITTER_SEARCH_DOMAIN         @"search.twitter.com"
#endif
#define HTTP_POST_METHOD        @"POST"
#define MAX_MESSAGE_LENGTH      140 // Twitter recommends tweets of max 140 chars

#define DEFAULT_CLIENT_NAME     @"Twitbit"
#define DEFAULT_CLIENT_VERSION  @"1.0"
#define DEFAULT_CLIENT_URL      @"http://twitbitapp.com"
#define DEFAULT_CLIENT_TOKEN	@"twitbitapp"

#define URL_REQUEST_TIMEOUT     25.0 // Twitter usually fails quickly if it's going to fail at all.
#define DEFAULT_TWEET_COUNT		20


@interface MGTwitterEngine (PrivateMethods)

// Utility methods
- (NSDateFormatter *)_HTTPDateFormatter;
- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;
- (NSDate *)_HTTPToDate:(NSString *)httpDate;
- (NSString *)_dateToHTTP:(NSDate *)date;
- (NSString *)_encodeString:(NSString *)string;

- (NSString *)baseUrlWithPath:(NSString *)path requestType:(MGTwitterRequestType)requestType params:(NSDictionary *)params;
+ (NSString *)apiDomain;

// Connection/Request methods
- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType;

// Parsing methods
- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection;

// Delegate methods
- (BOOL) _isValidDelegateForSelector:(SEL)selector;

@end


@implementation MGTwitterEngine


#pragma mark Constructors


+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)theDelegate
{
    return [[[MGTwitterEngine alloc] initWithDelegate:theDelegate] autorelease];
}


- (MGTwitterEngine *)initWithDelegate:(NSObject *)newDelegate
{
    if (self = [super init]) {
        _delegate = newDelegate; // deliberately weak reference
        _connections = [[NSMutableDictionary alloc] initWithCapacity:0];
        _clientName = DEFAULT_CLIENT_NAME;
        _clientVersion = DEFAULT_CLIENT_VERSION;
        _clientURL = DEFAULT_CLIENT_URL;
		_clientSourceToken = DEFAULT_CLIENT_TOKEN;
		_APIDomain = [[self class] apiDomain];
        _APIVersion = TWITTER_API_VERSION;
#if JSON_AVAILABLE || YAJL_AVAILABLE
		_searchDomain = TWITTER_SEARCH_DOMAIN;
#endif

        _secureConnection = YES;
		_clearsCookies = NO;
#if YAJL_AVAILABLE
		_deliveryOptions = MGTwitterEngineDeliveryAllResultsOption;
#endif
    }
    
    return self;
}


- (void)dealloc
{
    _delegate = nil;
    
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections release];
    
    [_username release];
    [_password release];
    [_clientName release];
    [_clientVersion release];
    [_clientURL release];
    [_clientSourceToken release];
	[_APIDomain release];
    [_APIVersion release];
#if JSON_AVAILABLE || YAJL_AVAILABLE
	[_searchDomain release];
#endif
    
    [super dealloc];
}


#pragma mark Configuration and Accessors


+ (NSString *)version
{
    // 1.0.0 = 22 Feb 2008
    // 1.0.1 = 26 Feb 2008
    // 1.0.2 = 04 Mar 2008
    // 1.0.3 = 04 Mar 2008
	// 1.0.4 = 11 Apr 2008
	// 1.0.5 = 06 Jun 2008
	// 1.0.6 = 05 Aug 2008
	// 1.0.7 = 28 Sep 2008
	// 1.0.8 = 01 Oct 2008
    return @"1.0.8";
}


- (NSString *)username
{
    return [[_username retain] autorelease];
}


- (NSString *)password
{
    return [[_password retain] autorelease];
}


- (void)setUsername:(NSString *)newUsername password:(NSString *)newPassword
{
    // Set new credentials.
    [_username release];
    _username = [newUsername retain];
    [_password release];
    _password = [newPassword retain];
    
	if ([self clearsCookies]) {
		// Remove all cookies for twitter, to ensure next connection uses new credentials.
		NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", 
							   (_secureConnection) ? @"https" : @"http", 
							   _APIDomain, _APIVersion];
		NSURL *url = [NSURL URLWithString:urlString];
		
		NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSEnumerator *enumerator = [[cookieStorage cookiesForURL:url] objectEnumerator];
		NSHTTPCookie *cookie = nil;
		while (cookie = [enumerator nextObject]) {
			[cookieStorage deleteCookie:cookie];
		}
	}
}


- (NSString *)clientName
{
    return [[_clientName retain] autorelease];
}


- (NSString *)clientVersion
{
    return [[_clientVersion retain] autorelease];
}


- (NSString *)clientURL
{
    return [[_clientURL retain] autorelease];
}


- (NSString *)clientSourceToken
{
    return [[_clientSourceToken retain] autorelease];
}


- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
{
    [_clientName release];
    _clientName = [name retain];
    [_clientVersion release];
    _clientVersion = [version retain];
    [_clientURL release];
    _clientURL = [url retain];
    [_clientSourceToken release];
    _clientSourceToken = [token retain];
}


- (NSString *)APIDomain
{
	return [[_APIDomain retain] autorelease];
}


- (void)setAPIDomain:(NSString *)domain
{
	[_APIDomain release];
	if (!domain || [domain length] == 0) {
		_APIDomain = [[self class] apiDomain];
	} else {
		_APIDomain = [domain retain];
	}
}


#if JSON_AVAILABLE || YAJL_AVAILABLE

- (NSString *)searchDomain
{
	return [[_searchDomain retain] autorelease];
}


- (void)setSearchDomain:(NSString *)domain
{
	[_searchDomain release];
	if (!domain || [domain length] == 0) {
		_searchDomain = [TWITTER_SEARCH_DOMAIN retain];
	} else {
		_searchDomain = [domain retain];
	}
}

#endif


- (BOOL)usesSecureConnection
{
    return _secureConnection;
}


- (void)setUsesSecureConnection:(BOOL)flag
{
    _secureConnection = flag;
}


- (BOOL)clearsCookies
{
	return _clearsCookies;
}


- (void)setClearsCookies:(BOOL)flag
{
	_clearsCookies = flag;
}

#if YAJL_AVAILABLE

- (MGTwitterEngineDeliveryOptions)deliveryOptions
{
	return _deliveryOptions;
}

- (void)setDeliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions
{
	_deliveryOptions = deliveryOptions;
}

#endif

#pragma mark Connection methods


- (int)numberOfConnections
{
    return [_connections count];
}


- (NSArray *)connectionIdentifiers
{
    return [_connections allKeys];
}


- (void)closeConnection:(NSString *)identifier
{
    MGTwitterHTTPURLConnection *connection = [_connections objectForKey:identifier];
    if (connection) {
        [connection cancel];
        [_connections removeObjectForKey:identifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished)])
			[_delegate connectionFinished];
    }
}


- (void)closeAllConnections
{
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections removeAllObjects];
}


#pragma mark Utility methods


- (NSDateFormatter *)_HTTPDateFormatter
{
    // Returns a formatter for dates in HTTP format (i.e. RFC 822, updated by RFC 1123).
    // e.g. "Sun, 06 Nov 1994 08:49:37 GMT"
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	//[dateFormatter setDateFormat:@"%a, %d %b %Y %H:%M:%S GMT"]; // won't work with -init, which uses new (unicode) format behaviour.
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss GMT"];
	return dateFormatter;
}


- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed
{
    // Append base if specified.
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    if (base) {
        [str appendString:base];
    }
    
    // Append each name-value pair.
    if (params) {
        int i;
        NSArray *names = [params allKeys];
        for (i = 0; i < [names count]; i++) {
            if (i == 0 && prefixed) {
                [str appendString:@"?"];
            } else if (i > 0) {
                [str appendString:@"&"];
            }
            NSString *name = [names objectAtIndex:i];
            [str appendString:[NSString stringWithFormat:@"%@=%@", 
             name, [self _encodeString:[params objectForKey:name]]]];
        }
    }
    
    return str;
}


- (NSDate *)_HTTPToDate:(NSString *)httpDate
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter dateFromString:httpDate];
}


- (NSString *)_dateToHTTP:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter stringFromDate:date];
}


- (NSString *)_encodeString:(NSString *)string
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                 (CFStringRef)string, 
                                                                 NULL, 
                                                                 (CFStringRef)@";/?:@&=$+{}<>,",
                                                                 kCFStringEncodingUTF8);
    return [result autorelease];
}


- (NSString *)getImageAtURL:(NSString *)urlString
{
    // This is a method implemented for the convenience of the client, 
    // allowing asynchronous downloading of users' Twitter profile images.
	NSString *encodedUrlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedUrlString];
    if (!url) {
        return nil;
    }
    
    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:URL_REQUEST_TIMEOUT];
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:MGTwitterImageRequest 
                                                        responseType:MGTwitterImage];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
    
    return [connection identifier];
}


#pragma mark Request sending methods

#define SET_AUTHORIZATION_IN_HEADER 1

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params 
                                body:(NSString *)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType
{
    /*
    // Construct appropriate URL string.
    NSString *fullPath = path;
    if (params) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }

#if JSON_AVAILABLE || YAJL_AVAILABLE
	NSString *domain = nil;
    NSString *version = nil;
	NSString *connectionType = nil;
	if (requestType == MGTwitterSearchRequest)
	{
		domain = _searchDomain;
        version = @"";
		connectionType = @"http";
	}
	else
	{
		domain = _APIDomain;
        version = [NSString stringWithFormat:@"/%@", _APIVersion];
		if (_secureConnection)
		{
			connectionType = @"https";
		}
		else
		{
			connectionType = @"http";
		}
	}
#else
	NSString *domain = _APIDomain;
    NSString *version = _APIVersion;
	NSString *connectionType = nil;
	if (_secureConnection)
	{
		connectionType = @"https";
	}
	else
	{
		connectionType = @"http";
	}
#endif
	
#if SET_AUTHORIZATION_IN_HEADER
    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@/%@", 
                           connectionType,
                           domain, version, fullPath];
#else    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@@%@%@/%@", 
                           connectionType, 
                           [self _encodeString:_username], [self _encodeString:_password], 
                           domain, version, fullPath];
#endif
     */

    NSString * urlString = [self baseUrlWithPath:path requestType:requestType params:params];
    
    NSURL *finalURL = [NSURL URLWithString:urlString];
    if (!finalURL) {
        return nil;
    }
    
    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:finalURL 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:URL_REQUEST_TIMEOUT];
    if (method) {
        [theRequest setHTTPMethod:method];
    }
    [theRequest setHTTPShouldHandleCookies:NO];
    
    // Set headers for client information, for tracking purposes at Twitter.
    [theRequest setValue:_clientName    forHTTPHeaderField:@"X-Twitter-Client"];
    [theRequest setValue:_clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
    [theRequest setValue:_clientURL     forHTTPHeaderField:@"X-Twitter-Client-URL"];
    
#if SET_AUTHORIZATION_IN_HEADER
	if ([self username] && [self password]) {
		// Set header for HTTP Basic authentication explicitly, to avoid problems with proxies and other intermediaries
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", [self username], [self password]];
		NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
		NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
		[theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
	}
#endif

    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
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


#pragma mark Parsing methods

#if JSON_AVAILABLE

- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSString * identifier = [[[connection identifier] copy] autorelease];
    NSData * jsonData = [connection data];
    MGTwitterRequestType requestType = [connection requestType];
    MGTwitterResponseType responseType = [connection responseType];

	NSURL *URL = [connection URL];

    [MGTwitterJSONParser parserWithJSON:jsonData
                               delegate:self
                   connectionIdentifier:identifier
                            requestType:requestType
                           responseType:responseType
                                    URL:URL];
}

#elif YAJL_AVAILABLE

- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSString *identifier = [[[connection identifier] copy] autorelease];
    NSData *jsonData = [connection data];
    MGTwitterRequestType requestType = [connection requestType];
    MGTwitterResponseType responseType = [connection responseType];

	NSURL *URL = [connection URL];

//	NSLog(@"jsonData = %@ from %@", [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease], URL);

    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesYAJLParser parserWithJSON:jsonData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersYAJLParser parserWithJSON:jsonData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesYAJLParser parserWithJSON:jsonData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscYAJLParser parserWithJSON:jsonData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
			break;
        case MGTwitterSearchResults:
 			[MGTwitterSearchYAJLParser parserWithJSON:jsonData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType URL:URL deliveryOptions:_deliveryOptions];
			break;
       default:
            break;
    }
}
#else
- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSString *identifier = [[[connection identifier] copy] autorelease];
    NSData *xmlData = [connection data];
    MGTwitterRequestType requestType = [connection requestType];
    MGTwitterResponseType responseType = [connection responseType];
    
#if USE_LIBXML
	NSURL *URL = [connection URL];

    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesLibXMLParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersLibXMLParser parserWithXML:xmlData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType URL:URL];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesLibXMLParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType URL:URL];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscLibXMLParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType URL:URL];
			break;
        default:
            break;
    }
#else
    // Determine which type of parser to use.
    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
            [MGTwitterStatusesParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
            [MGTwitterUsersParser parserWithXML:xmlData delegate:self 
                           connectionIdentifier:identifier requestType:requestType 
                                   responseType:responseType];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
            [MGTwitterMessagesParser parserWithXML:xmlData delegate:self 
                              connectionIdentifier:identifier requestType:requestType 
                                      responseType:responseType];
            break;
		case MGTwitterMiscellaneous:
			[MGTwitterMiscParser parserWithXML:xmlData delegate:self 
						  connectionIdentifier:identifier requestType:requestType 
								  responseType:responseType];
			break;
        default:
            break;
    }
#endif
}
#endif

#pragma mark Delegate methods

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((_delegate != nil) && [_delegate respondsToSelector:selector]);
}

#pragma mark MGTwitterParserDelegate methods

- (void)parsingSucceededForRequest:(NSString *)identifier 
                    ofResponseType:(MGTwitterResponseType)responseType 
                 withParsedObjects:(NSArray *)parsedObjects
{
    MGTwitterHTTPURLConnection * connection = [_connections objectForKey:identifier];
    if ([connection error]) {
        if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)]) {
            NSError * error = [connection error];
            NSDictionary * userInfo = error.userInfo;
            NSMutableDictionary * mutableInfo = userInfo ? [userInfo mutableCopy] : [[NSMutableDictionary alloc] init];

            NSString * errorMessage = nil;
            if (parsedObjects.count > 0 && [[parsedObjects objectAtIndex:0] objectForKey:@"error"] != nil)
                errorMessage = [[parsedObjects objectAtIndex:0] objectForKey:@"error"];
            if (errorMessage) {
                [mutableInfo setObject:errorMessage forKey:NSLocalizedDescriptionKey];
                NSString * errorDomain = [NSError twitterApiErrorDomain];
                [connection setError:[NSError errorWithDomain:errorDomain code:error.code userInfo:mutableInfo]];
            }
            [mutableInfo release];
            [_delegate requestFailed:identifier withError:[connection error]];
        }
    } else {
        // Forward appropriate message to _delegate, depending on responseType.
        switch (responseType) {
            case MGTwitterStatuses:
            case MGTwitterStatus:
                if ([self _isValidDelegateForSelector:@selector(statusesReceived:forRequest:)])
                    [_delegate statusesReceived:parsedObjects forRequest:identifier];
                break;
            case MGTwitterUsers:
            case MGTwitterUser:
                if ([self _isValidDelegateForSelector:@selector(userInfoReceived:forRequest:)])
                    [_delegate userInfoReceived:parsedObjects forRequest:identifier];
                break;
            case MGTwitterDirectMessages:
            case MGTwitterDirectMessage:
                if ([self _isValidDelegateForSelector:@selector(directMessagesReceived:forRequest:)])
                    [_delegate directMessagesReceived:parsedObjects forRequest:identifier];
                break;
            case MGTwitterMiscellaneous:
                if ([self _isValidDelegateForSelector:@selector(miscInfoReceived:forRequest:)])
                    [_delegate miscInfoReceived:parsedObjects forRequest:identifier];
                break;
#if JSON_AVAILABLE || YAJL_AVAILABLE
            case MGTwitterSearchResults:
                if ([self _isValidDelegateForSelector:@selector(searchResultsReceived:forRequest:)])
                    [_delegate searchResultsReceived:parsedObjects forRequest:identifier];
                break;
#endif
            default:
                break;
        }
    }
}

- (void)parsingFailedForRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType 
                      withError:(NSError *)error
{
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[_delegate requestFailed:requestIdentifier withError:error];
}

#if YAJL_AVAILABLE

- (void)parsedObject:(NSDictionary *)dictionary forRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType
{
	if ([self _isValidDelegateForSelector:@selector(receivedObject:forRequest:)])
		[_delegate receivedObject:dictionary forRequest:requestIdentifier];
}

#endif

#pragma mark NSURLConnection delegate methods


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge previousFailureCount] == 0 && ![challenge proposedCredential]) {
		NSURLCredential *credential = [NSURLCredential credentialWithUser:_username password:_password 
															  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it has enough information to create the NSURLResponse.
    // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [connection resetDataLength];
    
    // Get response code.
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    int statusCode = [resp statusCode];
    
    if (statusCode >= 400)
        // save for later; we want to parse any error strings we've received from Twitter
        [connection setError:[NSError errorWithDomain:@"HTTP" code:statusCode userInfo:nil]];
    else if (statusCode == 304 || [connection responseType] == MGTwitterGeneric) {
        // Not modified, or generic success.
		if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
			[_delegate requestSucceeded:[connection identifier]];
        if (statusCode == 304) {
            [self parsingSucceededForRequest:[connection identifier] 
                              ofResponseType:[connection responseType] 
                           withParsedObjects:[NSArray array]];
        }
        
        // Destroy the connection.
        [connection cancel];
        [_connections removeObjectForKey:[connection identifier]];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished)])
			[_delegate connectionFinished];
    }
    
    if (NO) {
        // Display headers for debugging.
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
        NSLog(@"(%d) [%@]:\r%@", 
              [resp statusCode], 
              [NSHTTPURLResponse localizedStringForStatusCode:[resp statusCode]], 
              [resp allHeaderFields]);
    }
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the receivedData.
    [connection appendData:data];
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didFailWithError:(NSError *)error
{
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[_delegate requestFailed:[connection identifier] withError:error];
    
    // Release the connection.
    [_connections removeObjectForKey:[connection identifier]];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished)])
		[_delegate connectionFinished];
}


- (void)connectionDidFinishLoading:(MGTwitterHTTPURLConnection *)connection
{
    // Inform delegate.
    if (![connection error] && [self _isValidDelegateForSelector:@selector(requestSucceeded:)])
		[_delegate requestSucceeded:[connection identifier]];
    
    NSData *receivedData = [connection data];
    if (receivedData) {
        if (NO) {
            // Dump data as string for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            NSLog(@"Succeeded! Received %d bytes of data:\r\r%@", [receivedData length], dataString);
        }
        
        if (NO) {
            // Dump XML to file for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            [dataString writeToFile:[[NSString stringWithFormat:@"~/Desktop/twitter_messages.%@", API_FORMAT] stringByExpandingTildeInPath] 
                         atomically:NO encoding:NSUnicodeStringEncoding error:NULL];
        }
        
        if ([connection responseType] == MGTwitterImage) {
			// Create image from data.
#if TARGET_OS_IPHONE
            UIImage *image = [[[UIImage alloc] initWithData:[connection data]] autorelease];
#else
            NSImage *image = [[[NSImage alloc] initWithData:[connection data]] autorelease];
#endif
            
            // Inform delegate.
			if ([self _isValidDelegateForSelector:@selector(imageReceived:forRequest:)])
				[_delegate imageReceived:image forRequest:[connection identifier]];
        } else {
            // Parse data from the connection (either XML or JSON.)
            [self _parseDataForConnection:connection];
        }
    }
    
    // Release the connection.
    [_connections removeObjectForKey:[connection identifier]];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished)])
		[_delegate connectionFinished];
}


#pragma mark -
#pragma mark Twitter API methods
#pragma mark -


#pragma mark Account methods


- (NSString *)checkUserCredentials
{
    NSString *path = [NSString stringWithFormat:@"account/verify_credentials.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)endUserSession
{
    NSString *path = @"account/end_session"; // deliberately no format specified
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterGeneric];
}


- (NSString *)enableUpdatesFor:(NSString *)username
{
    // i.e. follow
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"friendships/create/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)disableUpdatesFor:(NSString *)username
{
    // i.e. no longer follow
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"friendships/destroy/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)isUser:(NSString *)username1 receivingUpdatesFor:(NSString *)username2
{
	if (!username1 || !username2) {
        return nil;
    }
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:username1 forKey:@"user_a"];
	[params setObject:username2 forKey:@"user_b"];
	
    NSString *path = [NSString stringWithFormat:@"friendships/exists.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterMiscellaneous];
}


- (NSString *)enableNotificationsFor:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"notifications/follow/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)disableNotificationsFor:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"notifications/leave/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)getRateLimitStatus
{
	NSString *path = [NSString stringWithFormat:@"account/rate_limit_status.%@", API_FORMAT];
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterMiscellaneous];
}


// TODO: this API is deprecated, change to account/update_profile
- (NSString *)setLocation:(NSString *)location
{
	if (!location) {
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"account/update_location.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:location forKey:@"location"];
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)setNotificationsDeliveryMethod:(NSString *)method
{
	NSString *deliveryMethod = method;
	if (!method || [method length] == 0) {
		deliveryMethod = @"none";
	}
	
	NSString *path = [NSString stringWithFormat:@"account/update_delivery_device.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (deliveryMethod) {
        [params setObject:deliveryMethod forKey:@"device"];
    }
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:params body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterUser];
}


- (NSString *)block:(NSString *)username
{
	if (!username) {
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"blocks/create/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterUser];
}


- (NSString *)unblock:(NSString *)username
{
	if (!username) {
		return nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"blocks/destroy/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterUser];
}

- (NSString *)isBlocking:(NSString *)username
{
    if (!username) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"blocks/exists/%@.%@", username, API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)testService
{
	NSString *path = [NSString stringWithFormat:@"help/test.%@", API_FORMAT];
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterMiscellaneous];
}


- (NSString *)getDowntimeSchedule
{
	NSString *path = [NSString stringWithFormat:@"help/downtime_schedule.%@", API_FORMAT];
	
	return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest
                           responseType:MGTwitterMiscellaneous];
}


#pragma mark Retrieving updates


- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum
{
	// Included for backwards-compatibility.
    return [self getFollowedTimelineFor:username since:date startingAtPage:pageNum count:0]; // zero means default
}


- (NSString *)getFollowedTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)count
{
	NSString *path = [NSString stringWithFormat:@"statuses/friends_timeline.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/friends_timeline/%@.%@", username, API_FORMAT];
    }
	int tweetCount = DEFAULT_TWEET_COUNT;
	if (count > 0) {
		tweetCount = count;
	}
	[params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getFollowedTimelineFor:(NSString *)username sinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)count
{
	NSString *path = [NSString stringWithFormat:@"statuses/home_timeline.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if ([updateID longLongValue] > 0) {
        [params setObject:[NSString stringWithFormat:@"%@", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/home_timeline/%@.%@", username, API_FORMAT];
    }
	int tweetCount = DEFAULT_TWEET_COUNT;
	if (count > 0) {
		tweetCount = count;
	}
	[params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date count:(int)numUpdates
{
	// Included for backwards-compatibility.
    return [self getUserTimelineFor:username since:date startingAtPage:0 count:numUpdates];
}


- (NSString *)getUserTimelineFor:(NSString *)username since:(NSDate *)date startingAtPage:(int)pageNum count:(int)numUpdates
{
	NSString *path = [NSString stringWithFormat:@"statuses/user_timeline.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
	if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (numUpdates > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", numUpdates] forKey:@"count"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/user_timeline/%@.%@", username, API_FORMAT];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getUserTimelineFor:(NSString *)username sinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)numUpdates
{
	NSString *path = [NSString stringWithFormat:@"statuses/user_timeline.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if ([updateID longLongValue] > 0) {
        [params setObject:[NSString stringWithFormat:@"%@", updateID] forKey:@"since_id"];
    }
	if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (numUpdates > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", numUpdates] forKey:@"count"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"statuses/user_timeline/%@.%@", username, API_FORMAT];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}

// The following API is deprecated. Use getUserTimelineFor: instead.
/*
- (NSString *)getUserUpdatesArchiveStartingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"account/archive.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}
*/


- (NSString *)getPublicTimelineSinceID:(int)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/public_timeline.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", updateID] forKey:@"since_id"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}

- (NSString *)getRepliesStartingAtPage:(int)pageNum
{
	// Included for backwards-compatibility.
    return [self getRepliesSinceID:0 startingAtPage:pageNum count:0]; // zero means default
}

- (NSString *)getRepliesSince:(NSDate *)date startingAtPage:(int)pageNum count:(int)count
{
	NSString *path = [NSString stringWithFormat:@"statuses/replies.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
	int tweetCount = DEFAULT_TWEET_COUNT;
	if (count > 0) {
		tweetCount = count;
	}
	[params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getRepliesSinceID:(int)updateID startingAtPage:(int)pageNum count:(int)count
{
	NSString *path = [NSString stringWithFormat:@"statuses/replies.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
	int tweetCount = DEFAULT_TWEET_COUNT;
	if (count > 0) {
		tweetCount = count;
	}
	[params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}




- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"favorites.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (username) {
        path = [NSString stringWithFormat:@"favorites/%@.%@", username, API_FORMAT];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}


- (NSString *)getUpdate:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/show/%@.%@", updateID, API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatus];
}


#pragma mark Retrieving direct messages


- (NSString *)getDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"direct_messages.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


- (NSString *)getDirectMessagesSinceID:(int)updateID startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"direct_messages.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}

- (NSString *)getDirectMessagesSinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)count; // direct_messages
{
    NSString *path = [NSString stringWithFormat:@"direct_messages.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if ([updateID longLongValue] > 0) {
        [params setObject:[NSString stringWithFormat:@"%@", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}

- (NSString *)getSentDirectMessagesSince:(NSDate *)date startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/sent.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (date) {
        [params setObject:[self _dateToHTTP:date] forKey:@"since"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


- (NSString *)getSentDirectMessagesSinceID:(int)updateID startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/sent.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (updateID > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}

- (NSString *)getSentDirectMessagesSinceID:(NSString *)updateID startingAtPage:(int)pageNum count:(int)count; // direct_messages/sent
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/sent.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if ([updateID longLongValue] > 0) {
        [params setObject:[NSString stringWithFormat:@"%@", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterDirectMessagesRequest 
                           responseType:MGTwitterDirectMessages];
}


#pragma mark Retrieving user information


- (NSString *)getUserInformationFor:(NSString *)usernameOrID
{
    if (!usernameOrID) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"users/show/%@.%@", usernameOrID, API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)getUserInformationForEmail:(NSString *)email
{
    NSString *path = [NSString stringWithFormat:@"users/show.%@", API_FORMAT];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (email) {
        [params setObject:email forKey:@"email"];
    } else {
        return nil;
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUser];
}


- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"statuses/friends.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        path = [NSString stringWithFormat:@"statuses/friends/%@.%@", username, API_FORMAT];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}

- (NSString *)getRecentlyUpdatedFriendsFor:(NSString *)username cursor:(NSString *)cursor
{
    NSString *path = [NSString stringWithFormat:@"statuses/friends.%@", API_FORMAT];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        path = [NSString stringWithFormat:@"statuses/friends/%@.%@", username, API_FORMAT];
    }
    if (cursor) {
        [params setObject:cursor forKey:@"cursor"];
    }

    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}

- (NSString *)getFollowersFor:(NSString *)username startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"statuses/followers.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        [params setObject:username forKey:@"screen_name"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}

- (NSString *)getFollowersFor:(NSString *)username cursor:(NSString *)cursor
{
    NSString *path = [NSString stringWithFormat:@"statuses/followers.%@", API_FORMAT];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (username) {
        [params setObject:username forKey:@"screen_name"];
    }
    if (cursor) {
        [params setObject:cursor forKey:@"cursor"];
    }

    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}

- (NSString *)getFollowersIncludingCurrentStatus:(BOOL)flag
{
    NSString *path = [NSString stringWithFormat:@"statuses/followers.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (!flag) {
        [params setObject:@"true" forKey:@"lite"]; // slightly bizarre, but correct.
    }
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}


- (NSString *)getFeaturedUsers
{
    NSString *path = [NSString stringWithFormat:@"statuses/featured.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}


#pragma mark Sending and editing updates


- (NSString *)sendUpdate:(NSString *)status
{
    return [self sendUpdate:status inReplyTo:nil];
}

- (NSString *)sendUpdate:(NSString *)status coordinate:(CLLocationCoordinate2D)coord
{
    return [self sendUpdate:status coordinate:coord inReplyTo:nil];
}

- (NSString *)sendUpdate:(NSString *)status inReplyTo:(NSString *)updateID
{
    if (!status) {
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"statuses/update.%@", API_FORMAT];
    
    NSString *trimmedText = status;
    if ([trimmedText length] > MAX_MESSAGE_LENGTH) {
        trimmedText = [trimmedText substringToIndex:MAX_MESSAGE_LENGTH];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:trimmedText forKey:@"status"];
    if (updateID && [updateID length] > 0) {
        [params setObject:updateID forKey:@"in_reply_to_status_id"];
    }
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterStatusSend 
                           responseType:MGTwitterStatus];
}

- (NSString *)sendUpdate:(NSString *)status coordinate:(CLLocationCoordinate2D)coord inReplyTo:(NSString *)updateID
{
    if (!status) {
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"statuses/update.%@", API_FORMAT];
    
    NSString *trimmedText = status;
    if ([trimmedText length] > MAX_MESSAGE_LENGTH) {
        trimmedText = [trimmedText substringToIndex:MAX_MESSAGE_LENGTH];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:trimmedText forKey:@"status"];
    if (updateID && [updateID length] > 0) {
        [params setObject:updateID forKey:@"in_reply_to_status_id"];
    }
    [params setObject:[NSString stringWithFormat:@"%f", coord.latitude] forKey:@"lat"];
    [params setObject:[NSString stringWithFormat:@"%f", coord.longitude] forKey:@"long"];
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterStatusSend 
                           responseType:MGTwitterStatus];
}

- (NSString *)sendRetweet:(NSString *)updateID
{
    if (!updateID) {
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"statuses/retweet/%@.%@", updateID, API_FORMAT];

    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path
                        queryParameters:[NSDictionary dictionary]
                                   body:nil
                            requestType:MGTwitterStatusSend
                           responseType:MGTwitterStatus];
}

- (NSString *)deleteUpdate:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"statuses/destroy/%@.%@", updateID, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterStatus];
}


- (NSString *)markUpdate:(NSString *)updateID asFavorite:(BOOL)flag;
{
    NSString *path = [NSString stringWithFormat:@"favorites/%@/%@.%@", 
                      (flag) ? @"create" : @"destroy" ,
                      updateID, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterStatus];
}

// Getting mentions
- (NSString *)getMentionsSinceID:(NSString *)updateID
                            page:(int)pageNum
                           count:(int)count
{
    NSString *path = [NSString stringWithFormat:@"statuses/mentions.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if ([updateID longLongValue] > 0) {
        [params setObject:[NSString stringWithFormat:@"%@", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    int tweetCount = DEFAULT_TWEET_COUNT;
    if (count > 0) {
        tweetCount = count;
    }
    [params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}

// Getting retweets
- (NSString *)getRetweetsSinceID:(NSString *)updateID
                            page:(int)pageNum
                           count:(int)count
{
    NSString *path = [NSString stringWithFormat:@"statuses/retweeted_to_me.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if ([updateID longLongValue] > 0) {
        [params setObject:[NSString stringWithFormat:@"%@", updateID] forKey:@"since_id"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    int tweetCount = DEFAULT_TWEET_COUNT;
    if (count > 0) {
        tweetCount = count;
    }
    [params setObject:[NSString stringWithFormat:@"%d", tweetCount] forKey:@"count"];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}

#pragma mark Sending and editing direct messages


- (NSString *)sendDirectMessage:(NSString *)message to:(NSString *)username
{
    if (!message || !username) {
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"direct_messages/new.%@", API_FORMAT];

    NSString *trimmedText = message;
    if ([trimmedText length] > MAX_MESSAGE_LENGTH) {
        trimmedText = [trimmedText substringToIndex:MAX_MESSAGE_LENGTH];
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    [params setObject:trimmedText forKey:@"text"];
    [params setObject:username forKey:@"user"];
    NSString *body = [self _queryStringWithBase:nil parameters:params prefixed:NO];

    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path 
                        queryParameters:params body:body 
                            requestType:MGTwitterDirectMessageSend 
                           responseType:MGTwitterDirectMessage];
}


- (NSString *)deleteDirectMessage:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/destroy/%@.%@", updateID, API_FORMAT];
    
    return [self _sendRequestWithMethod:HTTP_POST_METHOD path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterDirectMessage];
}

- (NSString *)getDirectMessage:(NSString *)updateID
{
    NSString *path = [NSString stringWithFormat:@"direct_messages/show/%@.%@", updateID, API_FORMAT];

    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterAccountRequest 
                           responseType:MGTwitterDirectMessage];
}

- (NSString *)getListsFor:(NSString *)username cursor:(NSString *)cursor
{
    if (!username)
        return nil;

    NSString *path = [NSString stringWithFormat:@"%@/lists.%@", username, API_FORMAT];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (cursor) {
        [params setObject:cursor forKey:@"cursor"];
    }

    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}

- (NSString *)getListSubscriptionsFor:(NSString *)username cursor:(NSString *)cursor
{
    if (!username)
        return nil;

    NSString *path = [NSString stringWithFormat:@"%@/lists/subscriptions.%@", username, API_FORMAT];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    if (cursor) {
        [params setObject:cursor forKey:@"cursor"];
    }

    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterStatusesRequest 
                           responseType:MGTwitterStatuses];
}

- (NSString *)fetchStatusesForListWithId:(NSNumber *)listId ownedByUser:(NSString *)username
                           sinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page count:(NSNumber *)count
{
    if (!username || !listId)
        return nil;

    NSString * path = [NSString stringWithFormat:@"%@/lists/%@/statuses.%@", username, listId, API_FORMAT];

    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    if (updateId && [updateId longLongValue] > 0)
        [params setObject:[updateId description] forKey:@"since_id"];
    if (page)
        [params setObject:[page description] forKey:@"page"];
    if (count)
        [params setObject:[count description] forKey:@"per_page"];

    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil
                            requestType:MGTwitterStatusesRequest
                           responseType:MGTwitterStatuses];
}

#if JSON_AVAILABLE || YAJL_AVAILABLE

#pragma mark Search

- (NSString *)getSearchResultsForQuery:(NSString *)query
{
    return [self getSearchResultsForQuery:query sinceID:nil maxID:nil startingAtPage:0 count:0]; // zero means default
}

- (NSString *)getSearchResultsForQuery:(NSString *)query sinceID:(NSString *)updateID maxID:(NSString *)maxID startingAtPage:(int)pageNum count:(int)count
{
    NSString *path = [NSString stringWithFormat:@"search.%@", API_FORMAT];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	if (query) {
		[params setObject:query forKey:@"q"];
	}
    if ([updateID longLongValue] > 0) {
        [params setObject:updateID forKey:@"since_id"];
    }
    if ([maxID longLongValue] > 0) {
        [params setObject:maxID forKey:@"max_id"];
    }
	if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"rpp"];
    }
	
	/*
	NOTE: These parameters are also available but not implemented yet:
	
		lang: restricts tweets to the given language, given by an ISO 639-1 code.

			Ex: http://search.twitter.com/search.atom?lang=en&q=devo

		geocode: returns tweets by users located within a given radius of the given latitude/longitude, where the user's
			location is taken from their Twitter profile. The parameter value is specified by "latitide,longitude,radius",
			where radius units must be specified as either "mi" (miles) or "km" (kilometers).

			Note that you cannot use the near operator via the API to geocode arbitrary locations; however you can use this
			geocode parameter to search near geocodes directly.

			Ex: http://search.twitter.com/search.atom?geocode=40.757929%2C-73.985506%2C25km.
	*/

	
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterSearchRequest 
                           responseType:MGTwitterSearchResults];
}

- (NSString *)getSearchResultsForQuery:(NSString *)query
                               sinceID:(NSString *)updateID
                                 maxID:(NSString *)maxID
                        startingAtPage:(int)pageNum
                                 count:(int)count
                              latitude:(float)latitude
                             longitude:(float)longitude
                                radius:(int)radius
                       radiusIsInMiles:(BOOL)radiusIsInMiles
{
    NSString *path = [NSString stringWithFormat:@"search.%@", API_FORMAT];
    
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
	if (query) {
		[params setObject:query forKey:@"q"];
	}
    if ([updateID longLongValue] > 0) {
        [params setObject:[NSString stringWithFormat:@"%@", updateID] forKey:@"since_id"];
    }
    if ([maxID longLongValue] > 0) {
        [params setObject:maxID forKey:@"max_id"];
    }
	if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }
    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"rpp"];
    }

    NSString * geocode =
        [NSString stringWithFormat:@"%.6f,%.6f,%d%@",
        latitude, longitude, radius, radiusIsInMiles ? @"mi" : @"km"];
    [params setObject:geocode forKey:@"geocode"];
	
    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterSearchRequest 
                           responseType:MGTwitterSearchResults];
}

- (NSString *)getTrends
{
    NSString *path = [NSString stringWithFormat:@"trends.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterSearchRequest 
                           responseType:MGTwitterSearchResults];
}

- (NSString *)getCurrentTrends
{
    NSString *path = [NSString stringWithFormat:@"trends/current.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterSearchRequest 
                           responseType:MGTwitterSearchResults];
}

- (NSString *)getDailyTrends
{
    NSString *path = [NSString stringWithFormat:@"trends/daily.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterSearchRequest 
                           responseType:MGTwitterSearchResults];
}

- (NSString *)getWeeklyTrends
{
    NSString *path = [NSString stringWithFormat:@"trends/weekly.%@", API_FORMAT];
    
    return [self _sendRequestWithMethod:nil path:path queryParameters:nil body:nil 
                            requestType:MGTwitterSearchRequest 
                           responseType:MGTwitterSearchResults];
}

- (NSString *)getUserSearchResultsForQuery:(NSString *)query count:(int)count startingAtPage:(int)pageNum
{
    NSString *path = [NSString stringWithFormat:@"users/search.%@", API_FORMAT];

    if (!query)
        return nil;

    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    [params setObject:query forKey:@"q"];

    if (count > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"per_page"];
    }
    if (pageNum > 0) {
        [params setObject:[NSString stringWithFormat:@"%d", pageNum] forKey:@"page"];
    }

    return [self _sendRequestWithMethod:nil path:path queryParameters:params body:nil 
                            requestType:MGTwitterUserInfoRequest 
                           responseType:MGTwitterUsers];
}


#endif

- (NSString *)baseUrlWithPath:(NSString *)path
                  requestType:(MGTwitterRequestType)requestType
                       params:(NSDictionary *)params
{
    NSString *fullPath = path;
    if (params) {
        fullPath = [self _queryStringWithBase:fullPath
                                   parameters:params
                                     prefixed:YES];
    }

#if JSON_AVAILABLE || YAJL_AVAILABLE
	NSString *domain = nil;
    NSString *version = nil;
	NSString *connectionType = nil;
	if (requestType == MGTwitterSearchRequest)
	{
		domain = _searchDomain;
        version = @"";
		connectionType = @"http";
	}
	else
	{
		domain = _APIDomain;
        version = [[self class] useVersionedApi] ? [NSString stringWithFormat:@"/%@", _APIVersion] : @"";

		if (_secureConnection)
		{
			connectionType = @"https";
		}
		else
		{
			connectionType = @"http";
		}
	}
#else
	NSString *domain = _APIDomain;
    NSString *version = _APIVersion;
	NSString *connectionType = nil;
	if (_secureConnection)
	{
		connectionType = @"https";
	}
	else
	{
		connectionType = @"http";
	}
#endif

	NSString * urlString = nil;
#if SET_AUTHORIZATION_IN_HEADER
    if ([[self class] useVersionedApi])
        urlString = [NSString stringWithFormat:@"%@://%@/%@/%@", connectionType, domain, version, fullPath];
    else
        urlString = [NSString stringWithFormat:@"%@://%@/%@", connectionType, domain, fullPath];
#else
    if ([[self class] useVersionedApi])
        urlString = [NSString stringWithFormat:@"%@://%@:%@@%@%@/%@", connectionType, [self _encodeString:_username], [self _encodeString:_password], domain, version, fullPath];
    else
        urlString = [NSString stringWithFormat:@"%@://%@:%@@%@/%@", connectionType, [self _encodeString:_username], [self _encodeString:_password], domain, fullPath];
#endif

    return urlString;
}

+ (BOOL)useVersionedApi
{
    // Set to YES to use a versioned API, e.g.:
    //   https://api.twitter.com/1/users/show/rwzombie.xml
    // Set to NO to use old, non-versioned API, e.g.:
    //   https://twitter.com/users/show/rwzombie.xml
    // Using the versioned API is important as Twitter changes their API
    // frequently, but we are currently getting pretty constant "untrusted
    // server certificate" errors. Waiting until it stabilizes before switching
    // over.
    return YES;
}

+ (NSString *)apiDomain
{
    return [[self class] useVersionedApi] ? TWITTER_DOMAIN_VERSIONED : TWITTER_DOMAIN_UNVERSIONED;
}

@end

@implementation NSError (MGTwitterEngine)

+ (NSString *)twitterApiErrorDomain
{
    return @"Twitter API";
}

@end
