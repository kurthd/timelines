//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateDescription : NSObject
{
    NSString * dateString;
    NSString * timeString;
    NSString * amPmString;
}

- (id)initWithDateString:(NSString *)dateString
    timeString:(NSString *)timeString amPmString:(NSString *)amPmString;

@property (nonatomic, readonly) NSString * dateString;
@property (nonatomic, readonly) NSString * timeString;
@property (nonatomic, readonly) NSString * amPmString;

@end
