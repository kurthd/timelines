//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Tweet.h"
#import "DirectMessage.h"

@interface TweetInfo : NSObject 
{
    NSDate * timestamp;
    NSNumber * truncated;
    NSString * identifier;
    NSString * text;
    NSString * source;
    User * user;
    User * recipient;
    NSNumber * favoritedCount;
}

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * truncated;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) User * user;
@property (nonatomic, retain) User * recipient;
@property (nonatomic, retain) NSNumber * favoritedCount;

- (NSComparisonResult)compare:(TweetInfo *)tweetInfo;

+ (TweetInfo *)createFromTweet:(Tweet *)tweet;
+ (TweetInfo *)createFromDirectMessage:(DirectMessage *)directMessage;

@end
