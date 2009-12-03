//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Trend : NSObject
{
    NSString * name;
    NSString * explanation;
    NSString * query;
}

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * explanation;
@property (nonatomic, copy) NSString * query;

@end
