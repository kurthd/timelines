//
//  InstapaperCredentials.h
//  twitch
//
//  Created by John A. Debay on 8/31/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;

@interface InstapaperCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) TwitterCredentials * credentials;

@end



