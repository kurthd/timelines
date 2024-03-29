//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HtmlEncodingAdditions)

- (NSString *)stringByDecodingHtmlEntities;

@end

@interface NSString (UrlEncodingAdditions)

- (NSString *)urlEncodedString;
- (NSString *)urlEncodedStringWithEscapedAllowedCharacters:(NSString *)allowed;

@end