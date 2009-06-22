//
//  DirectMessage.h
//  twitch
//
//  Created by John A. Debay on 6/22/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface DirectMessage :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * sourceApiRequestType;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) User * recipient;
@property (nonatomic, retain) User * sender;

@end



