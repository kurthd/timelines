//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessage.h"

@interface DirectMessage (GeneralHelpers)

- (NSString *)textAsHtml;

- (NSString *)htmlDecodedText;

// If at least one photo link is contained within the tweet, this method will
// return one of them (consistently), otherwise nil; this method returns the
// the webpage in which the photo is displayed, not the link to the photo
// itself
- (NSString *)photoUrlWebpage;

// The url of the actual photo in the webpage above
- (NSString *)photoUrl;
- (void)setPhotoUrl:(NSString *)photoUrl;

@end