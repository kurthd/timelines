//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitPicResponseParser : NSObject
{
    NSString * error;
    NSString * mediaId;
    NSString * mediaUrl;

    NSMutableString * value;
    NSXMLParser * parser;
}

@property (nonatomic, copy, readonly) NSString * error;
@property (nonatomic, copy, readonly) NSString * mediaId;
@property (nonatomic, copy, readonly) NSString * mediaUrl;

- (id)init;

- (void)parse:(NSData *)xml;

@end
