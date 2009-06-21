//
//  TwitterCredentials.h
//  twitch
//
//  Created by John A. Debay on 6/21/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Account;

@interface TwitterCredentials :  NSManagedObject  
{
}

@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;
@property (nonatomic, retain) Account * account;

@end



