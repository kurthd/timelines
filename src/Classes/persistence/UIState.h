//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIState : NSObject
{
    NSUInteger selectedTab;
    NSUInteger selectedTimelineFeed;
    NSString * viewedTweetId;
    NSArray * tabOrder;
}

@property (nonatomic, assign) NSUInteger selectedTab;
@property (nonatomic, assign) NSUInteger selectedTimelineFeed;
@property (nonatomic, copy) NSString * viewedTweetId;
@property (nonatomic, copy) NSArray * tabOrder;
    
@end
