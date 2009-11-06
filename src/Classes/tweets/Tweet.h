//
//  Tweet.h
//  twitch
//
//  Created by John A. Debay on 10/9/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TweetLocation;
@class User;

@interface Tweet :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * inReplyToTwitterUsername;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSNumber * truncated;
@property (nonatomic, retain) NSNumber * favorited;
@property (nonatomic, retain) NSNumber * inReplyToTwitterTweetId;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * inReplyToTwitterUserId;
@property (nonatomic, retain) TweetLocation * location;
@property (nonatomic, retain) User * user;

@end



