//
//  DirectMessage.h
//  twitch
//
//  Created by John A. Debay on 6/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;
@class User;

@interface DirectMessage :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * sourceApiRequestType;
@property (nonatomic, retain) User * sender;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) User * recipient;

@end



