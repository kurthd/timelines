//
//  TwitterList.h
//  twitch
//
//  Created by John A. Debay on 11/10/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface TwitterList :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSNumber * memberCount;
@property (nonatomic, retain) NSNumber * subscriberCount;
@property (nonatomic, retain) NSString * mode;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uri;
@property (nonatomic, retain) User * user;

@end



