//
//  Tweet.h
//  twitch
//
//  Created by John A. Debay on 6/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface Tweet :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * inReplyToTwitterUsername;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSNumber * truncated;
@property (nonatomic, retain) NSNumber * favorited;
@property (nonatomic, retain) NSString * inReplyToTwitterTweetId;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * inReplyToTwitterUserId;
@property (nonatomic, retain) User * user;

@end



