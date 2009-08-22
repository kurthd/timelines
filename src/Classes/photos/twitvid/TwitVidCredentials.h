//
//  TwitVidCredentials.h
//  twitch
//
//  Created by John A. Debay on 8/20/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "PhotoServiceCredentials.h"


@interface TwitVidCredentials :  PhotoServiceCredentials  
{
}

@property (nonatomic, retain) NSString * username;

@end



