//
//  FlickrTag.h
//  twitch
//
//  Created by John A. Debay on 8/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>

@class FlickrCredentials;

@interface FlickrTag :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) FlickrCredentials * credentials;

@end



