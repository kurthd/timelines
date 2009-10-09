//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "MGTwitterJSONParser.h"
#import "JSON.h"

@interface MGTwitterJSONParser ()

- (NSArray *)parse;

- (BOOL)isValidDelegateForSelector:(SEL)selector;
- (void)parsingFinished:(NSArray *)parsedObjects;
- (void)parsingErrorOccurred:(NSError *)parseError;

@end

@implementation MGTwitterJSONParser

+ (id)parserWithJSON:(NSData *)theJSON
            delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier
         requestType:(MGTwitterRequestType)reqType
        responseType:(MGTwitterResponseType)respType URL:(NSURL *)URL
{
    id parser = [[self alloc] initWithJSON:theJSON 
                                  delegate:theDelegate 
                      connectionIdentifier:identifier 
                               requestType:reqType
                              responseType:respType
                                       URL:URL];

    return [parser autorelease];
}

- (void)dealloc
{
    [json release];
    [identifier release];
    [URL release];

    delegate = nil;
    [super dealloc];
}

- (id)initWithJSON:(NSData *)theJSON
          delegate:(NSObject *)theDelegate 
    connectionIdentifier:(NSString *)theIdentifier
             requestType:(MGTwitterRequestType)reqType 
            responseType:(MGTwitterResponseType)respType
                     URL:(NSURL *)theURL
{
    if (self = [super init]) {
        json = [theJSON retain];
        identifier = [theIdentifier retain];
        requestType = reqType;
        responseType = respType;
        URL = [theURL retain];
        delegate = theDelegate;

        NSArray * results = [self parse];
        [self parsingFinished:results];
    }

    return self;
}

- (NSArray *)parse
{
    NSArray * parsedObjects = nil;

    NSString * s =
        [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSLog(@"My json: '%@'", s);
    id results = [s JSONValue];
    [s release];

    if (results)
        if ([results isKindOfClass:[NSDictionary class]])
            parsedObjects = [NSArray arrayWithObject:results];
        else
            parsedObjects = results;
    else
        if ([json length] <= 5) {
            // this is a hack for API methods that return short JSON
            // responses that can't be parsed by YAJL. These include:
			//   friendships/exists: returns "true" or "false"
			//   help/test: returns "ok"
			NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
			if ([s isEqualToString:@"\"ok\""])
				[dictionary setObject:[NSNumber numberWithBool:YES]
                               forKey:@"ok"];
			else {
                BOOL isFriend = [s isEqualToString:@"true"];
				[dictionary setObject:[NSNumber numberWithBool:isFriend]
                               forKey:@"friends"];
			}
			parsedObjects = [NSArray arrayWithObject:dictionary];
        }

    return parsedObjects;
}

- (BOOL)isValidDelegateForSelector:(SEL)selector
{
	return (delegate && [delegate respondsToSelector:selector]);
}

- (void)parsingFinished:(NSArray *)parsedObjects
{
    SEL sel =
        @selector(parsingSucceededForRequest:ofResponseType:withParsedObjects:);

	if ([self isValidDelegateForSelector:sel])
		[delegate parsingSucceededForRequest:identifier
                              ofResponseType:responseType
                           withParsedObjects:parsedObjects];
}

- (void)parsingErrorOccurred:(NSError *)parseError
{
    SEL sel = @selector(parsingFailedForRequest:ofResponseType:withError:);
	if ([self isValidDelegateForSelector:sel])
		[delegate parsingFailedForRequest:identifier
                           ofResponseType:responseType
                                withError:parseError];
}

@end
