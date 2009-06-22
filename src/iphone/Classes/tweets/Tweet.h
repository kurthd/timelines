//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSManagedObject+TediousCodeAdditions.h"

@class User;

@interface Tweet :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * truncated;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) User * user;
@property (nonatomic, retain) NSNumber * favoritedCount;

+ (id)tweetWithId:(NSString *)anIdentifier
          context:(NSManagedObjectContext *)context;

@end
