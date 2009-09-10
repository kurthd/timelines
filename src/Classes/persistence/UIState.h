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

    NSUInteger selectedSearchBookmarkIndex;
    NSUInteger selectedPeopleBookmarkIndex;

    NSString * findPeopleText;
    NSString * searchText;
    BOOL nearbySearch;
}

@property (nonatomic, assign) NSUInteger selectedTab;
@property (nonatomic, assign) NSUInteger selectedTimelineFeed;
@property (nonatomic, copy) NSString * viewedTweetId;
@property (nonatomic, copy) NSArray * tabOrder;

@property (nonatomic, assign) NSUInteger selectedSearchBookmarkIndex;
@property (nonatomic, assign) NSUInteger selectedPeopleBookmarkIndex;

@property (nonatomic, copy) NSString * findPeopleText;
@property (nonatomic, copy) NSString * searchText;

@property (nonatomic, assign) BOOL nearbySearch;
    
@end
