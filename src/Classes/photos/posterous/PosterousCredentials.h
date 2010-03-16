//
//  PosterousCredentials.h
//  twitch
//
//  Created by John A. Debay on 3/15/10.
//  Copyright 2010 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "PhotoServiceCredentials.h"


@interface PosterousCredentials :  PhotoServiceCredentials  
{
}

@property (nonatomic, retain) NSString * username;

@end



