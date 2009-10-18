//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UrlAdditions)

- (NSArray *)extractUrls;
- (BOOL)containsUrls;

+ (NSString *)urlRegex;

@end
