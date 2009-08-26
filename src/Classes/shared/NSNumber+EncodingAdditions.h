//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (EncodingAdditions)

- (NSString *)encodeWithAlphabet:(NSString *)alphabet;
- (NSString *)base58EncodedString;

+ (NSNumber *)numberByDecodingString:(NSString *)encodedString
                        withAlphabet:(NSString *)alphabet;
+ (NSNumber *)numberWithBase58EncodedString:(NSString *)encodedString;

@end
