//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HtmlEncodingAdditions)

- (NSString *)stringByDecodingHtmlEntities;

@end

@interface NSString (EncodingAdditions)

- (NSString *)stringByEncodingWithAlphabet:(NSString *)alphabet;
- (NSString *)stringByEncodingWithBase58Encoding;

@end