//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSManagedObject+TediousCodeAdditions.h"

@class Tweet;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSNumber * following;
@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSString * webpage;
@property (nonatomic, retain) NSNumber * followers;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * profileImageUrl;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* tweets;

+ (id)userWithId:(NSString *)anIdentifier
         context:(NSManagedObjectContext *)context;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addTweetsObject:(Tweet *)value;
- (void)removeTweetsObject:(Tweet *)value;
- (void)addTweets:(NSSet *)value;
- (void)removeTweets:(NSSet *)value;

@end
