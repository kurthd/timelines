//
//  FlickrCredentials.h
//  twitch
//
//  Created by John A. Debay on 8/27/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "PhotoServiceCredentials.h"

@class FlickrTag;

@interface FlickrCredentials :  PhotoServiceCredentials  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSSet* tags;

@end


@interface FlickrCredentials (CoreDataGeneratedAccessors)
- (void)addTagsObject:(FlickrTag *)value;
- (void)removeTagsObject:(FlickrTag *)value;
- (void)addTags:(NSSet *)value;
- (void)removeTags:(NSSet *)value;

@end

