//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TwitterParsingHelpers)

- (NSDate *)twitterDateValue;

// If at least one photo link is contained within the tweet or direct messages,
// this method will return one of them (consistently), otherwise nil; this
// method returns the the webpage in which the photo is displayed, not the link
// to the photo itself
+ (NSString *)photoUrlWebpageFromTweetText:(NSString *)text;

@end
