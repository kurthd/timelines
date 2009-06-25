//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "User.h"
#import "Tweet.h"

@interface ResponseProcessor (ParsingHelpers)

- (void)populateUser:(User *)user fromData:(NSDictionary *)data;
- (void)populateTweet:(Tweet *)tweet fromData:(NSDictionary *)data;

@end
