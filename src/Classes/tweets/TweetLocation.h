//
//  TweetLocation.h
//  twitch
//
//  Created by John A. Debay on 10/8/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Tweet;

@interface TweetLocation :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) Tweet * tweet;

@end



