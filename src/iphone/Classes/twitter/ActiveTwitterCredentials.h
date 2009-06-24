//
//  ActiveTwitterCredentials.h
//  twitch
//
//  Created by John A. Debay on 6/23/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;

@interface ActiveTwitterCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) TwitterCredentials * credentials;

@end