//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ConvenienceMethods)

- (BOOL)containsString:(NSString *)s;

@end

#define LS(key) NSLocalizedString((key), @"")
