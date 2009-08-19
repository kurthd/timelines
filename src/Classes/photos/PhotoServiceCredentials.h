//
//  PhotoServiceCredentials.h
//  twitch
//
//  Created by John A. Debay on 8/18/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;

@interface PhotoServiceCredentials :  NSManagedObject  
{
}

@property (nonatomic, retain) TwitterCredentials * credentials;

- (NSString *)serviceName;
- (NSString *)accountDisplayName;

@end
