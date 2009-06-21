//
//  Account.h
//  twitch
//
//  Created by John A. Debay on 6/21/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Account :  NSManagedObject  
{
}

@property (nonatomic, copy) NSString * name;
@property (nonatomic, retain) NSManagedObject * credentials;

@end