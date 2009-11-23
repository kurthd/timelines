//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseProcessor.h"
#import "User.h"
#import "Tweet.h"
#import "Mention.h"
#import "DirectMessage.h"
#import "TwitterList.h"

@interface ResponseProcessor (ParsingHelpers)

- (Tweet *)createTweetFromStatus:(NSDictionary *)status
                     isUserTweet:(BOOL)isUserTweet
                  isSearchResult:(BOOL)isSearchResult
                     credentials:(TwitterCredentials *)credentials
                         context:(NSManagedObjectContext *)context;
- (Mention *)createMentionFromStatus:(NSDictionary *)status
                         credentials:(TwitterCredentials *)credentials
                             context:(NSManagedObjectContext *)context;

- (void)populateUser:(User *)user fromData:(NSDictionary *)data;
- (void)populateTweet:(Tweet *)tweet
             fromData:(NSDictionary *)data
       isSearchResult:(BOOL)isSearchResult
              context:(NSManagedObjectContext *)context;
- (void)populateDirectMessage:(DirectMessage *)dm fromData:(NSDictionary *)data;

- (void)populateList:(TwitterList *)list fromData:(NSDictionary *)data;

@end

@interface NSString (ParsingHelpers)
- (NSDate *)twitterDateValue;
@end

@interface NSNumber (ParsingHelpers)
- (NSNumber *)twitterIdentifierValue;
@end
