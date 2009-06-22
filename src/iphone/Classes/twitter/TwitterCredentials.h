//
//  TwitterCredentials.h
//  twitch
//
//  Created by John A. Debay on 6/21/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface TwitterCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;

@end