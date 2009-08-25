//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (EncodingAdditions)

- (NSString *)encodeWithAlphabet:(NSString *)alphabet;
- (NSString *)base58EncodedString;

@end
