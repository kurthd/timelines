//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "MGTwitterJSONParser.h"
#import "JSON.h"
#import "MGTwitterEngine.h"  // for twitterErrorDomain

@interface MGTwitterJSONParser ()

- (void)parseJsonInBackground:(NSData *)json;
- (void)parseJsonWrapper:(NSData *)json;
- (NSArray *)parse:(NSData *)json error:(NSError **)error;

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
        identifier = [theIdentifier retain];
        requestType = reqType;
        responseType = respType;
        URL = [theURL retain];
        delegate = theDelegate;

        [self parseJsonInBackground:theJSON];
    }

    return self;
}

- (void)parseJsonInBackground:(NSData *)json
{
    [self performSelectorInBackground:@selector(parseJsonWrapper:)
                           withObject:json];
}

- (void)parseJsonWrapper:(NSData *)json
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSError * error = nil;
    NSArray * parsedObjects = [self parse:json error:&error];

    id object = parsedObjects;
    SEL selector = @selector(parsingFinished:);

    /**
     * Some responses are not valid JSON fragments, but are short responses to
     * some queries. See comments in -parse:error: for more details. In those
     * cases, when we get legitimate responses, we will have an error instance,
     * but we will also have a parsedObjects instance. Don't treat this case as
     * an error.
     */
    if (error && !parsedObjects) {
        object = error;
        selector = @selector(parsingErrorOccurred:);
    } else {
        if (parsedObjects.count > 0) {
            NSDictionary * firstObject = [parsedObjects objectAtIndex:0];
            NSString * errorMessage = [firstObject objectForKey:@"error"];
            if (errorMessage) {
                NSString * errorDomain = [NSError twitterApiErrorDomain];
                NSString * errorKey = NSLocalizedDescriptionKey;
                NSDictionary * userInfo =
                    [NSDictionary dictionaryWithObject:errorMessage
                                                forKey:errorKey];
                NSError * error = [NSError errorWithDomain:errorDomain
                                                      code:0
                                                  userInfo:userInfo];

                object = error;
                selector = @selector(parsingErrorOccurred:);
            }
        }
    }

    [self performSelectorOnMainThread:selector
                           withObject:object
                        waitUntilDone:NO];
    [pool release];
}

- (NSArray *)parse:(NSData *)json error:(NSError **)error
{
    NSArray * parsedObjects = nil;

    NSString * s =
        [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    id results = [s JSONValueOrError:error];
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
            NSMutableDictionary * dictionary =
                [NSMutableDictionary dictionary];
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
