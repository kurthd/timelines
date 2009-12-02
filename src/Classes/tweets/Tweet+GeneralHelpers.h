//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tweet.h"

@interface Tweet (GeneralHelpers)

+ (NSString *)tweetTextAsHtml:(NSString *)text
                    timestamp:(NSDate *)timestamp
                       source:(NSString *)source
                     photoUrl:(NSString *)photoUrl
              photoUrlWebpage:(NSString *)photoUrlWebpage;

- (NSString *)textAsHtml;

- (NSString *)htmlDecodedText;

// Either the full name, if present, or the username, depending on the
// user's preferences.
- (NSString *)displayName;

// The unique URL for this tweet, or nil for Direct Messages.
- (NSString *)tweetUrl;

// If at least one photo link is contained within the tweet, this method will
// return one of them (consistently), otherwise nil; this method returns the
// the webpage in which the photo is displayed, not the link to the photo
// itself
- (NSString *)photoUrlWebpage;

// The url of the actual photo in the webpage above
- (NSString *)photoUrl;
- (void)setPhotoUrl:(NSString *)photoUrl;

@end