//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessage.h"

@interface DirectMessage (GeneralHelpers)

- (NSString *)textAsHtml;

- (NSString *)htmlDecodedText;

// The url of the actual photo in the webpage above
- (NSString *)photoUrl;
- (void)setPhotoUrl:(NSString *)photoUrl;

@end