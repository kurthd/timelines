//
//  TweetDraft.h
//  twitch
//
//  Created by John Debay on 9/21/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;

@interface TweetDraft :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * inReplyToTweetId;
@property (nonatomic, retain) NSString * inReplyToUsername;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) TwitterCredentials * credentials;

@end



