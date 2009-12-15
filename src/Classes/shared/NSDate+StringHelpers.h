//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DateDescription.h"

@interface NSDate (StringHelpers)

- (NSString *)shortDescription;
- (NSString *)shortDateAndTimeDescription;
- (NSString *)shortDateDescription;

+ (NSDate *)dateFromString:(NSString *)string format:(NSString *)formatString;

@end

@interface NSDate (TableViewCellHelpers)

- (DateDescription *)tableViewCellDescription;

@end