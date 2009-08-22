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

// these attributes should be moved somewhere else, maybe into a category
- (NSString *)serviceName;
- (NSString *)accountDisplayName;
- (BOOL)supportsPhotos;
- (BOOL)supportsVideo;


@end
