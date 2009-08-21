//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "YfrogResponseParser.h"

@interface YfrogResponseParser ()

@property (nonatomic, copy) NSString * error;
@property (nonatomic, copy) NSString * mediaId;
@property (nonatomic, copy) NSString * mediaUrl;

@property (nonatomic, retain) NSMutableString * value;
@property (nonatomic, retain) NSXMLParser * parser;

@end

@implementation YfrogResponseParser

@synthesize error, mediaId, mediaUrl;
@synthesize value, parser;

- (void)dealloc
{
    self.error = nil;
    self.mediaId = nil;
    self.mediaUrl = nil;
    self.value = nil;
    self.parser = nil;
    [super dealloc];
}

- (id)init
{
    return (self = [super init]);
}

- (void)parse:(NSData *)xml
{
    self.error = nil;
    self.mediaId = nil;
    self.mediaUrl = nil;
    self.value = nil;

    self.parser = [[[NSXMLParser alloc] initWithData:xml] autorelease];
    parser.delegate = self;

    [self.parser parse];
}

#pragma mark Parser delegate methods

- (void)parser:(NSXMLParser *)aParser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qualifiedName
         attributes:(NSDictionary *)attributes
{
    static NSSet * targets;

    if (!targets)
        targets = [[NSSet alloc] initWithObjects:@"mediaid", @"mediaurl", nil];

    if ([targets containsObject:elementName])
        self.value = [NSMutableString string];
    else if ([elementName isEqualToString:@"err"])
        self.error = [attributes objectForKey:@"msg"];
}

- (void)parser:(NSXMLParser *)aParser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"mediaid"])
        self.mediaId = self.value;
    else if ([elementName isEqualToString:@"mediaurl"])
        self.mediaUrl = self.value;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)chars
{
    [self.value appendString:chars];
}

@end
