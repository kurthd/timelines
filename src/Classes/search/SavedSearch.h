//
//  SavedSearch.h
//  twitch
//
//  Created by John A. Debay on 7/26/09.
//  Copyright 2009 High Order Bit, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface SavedSearch :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * query;
@property (nonatomic, retain) NSString * accountName;
@property (nonatomic, retain) NSNumber * displayOrder;

@end



