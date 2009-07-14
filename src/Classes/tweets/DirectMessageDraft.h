//
//  DirectMessageDraft.h
//  twitch
//
//  Created by John A. Debay on 7/14/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class TwitterCredentials;

@interface DirectMessageDraft :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * recipient;
@property (nonatomic, retain) TwitterCredentials * credentials;

@end