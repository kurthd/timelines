//
//  UserTwitterList.h
//  twitch
//
//  Created by John A. Debay on 11/10/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "TwitterList.h"

@class TwitterCredentials;

@interface UserTwitterList :  TwitterList  
{
}

@property (nonatomic, retain) TwitterCredentials * credentials;

@end