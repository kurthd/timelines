//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface RecentSearch :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * query;
@property (nonatomic, retain) NSString * accountName;
@property (nonatomic, retain) NSDate * timestamp;

@end



