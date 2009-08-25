//
//  FlickrCredentials.h
//  twitch
//
//  Created by John A. Debay on 8/24/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "PhotoServiceCredentials.h"


@interface FlickrCredentials :  PhotoServiceCredentials  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * token;

@end



