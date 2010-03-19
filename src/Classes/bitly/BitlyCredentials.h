//
//  BitlyCredentials.h
//  twitch
//
//  Created by John A. Debay on 3/18/10.
//  Copyright 2010 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;

@interface BitlyCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * apiKey;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) TwitterCredentials * credentials;

@end



