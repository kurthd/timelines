//
//  Avatar.h
//  twitch
//
//  Created by John A. Debay on 8/14/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface Avatar :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * thumbnailImageUrl;
@property (nonatomic, retain) NSString * fullImageUrl;
@property (nonatomic, retain) NSData * fullImage;
@property (nonatomic, retain) NSData * thumbnailImage;
@property (nonatomic, retain) User * user;

@end



