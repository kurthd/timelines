//
//  TwitPicCredentials.h
//  twitch
//
//  Created by John A. Debay on 6/28/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;

@interface TwitPicCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) TwitterCredentials * twitterCredentials;

@end