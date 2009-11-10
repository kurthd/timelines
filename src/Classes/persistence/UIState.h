//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIState : NSObject
{
    NSUInteger selectedTab;
    NSUInteger selectedTimelineFeed;
    NSArray * tabOrder;

    NSUInteger selectedSearchBookmarkIndex;
    NSUInteger selectedPeopleBookmarkIndex;

    NSString * findPeopleText;
    NSString * searchText;
    BOOL nearbySearch;

    NSInteger numNewMentions;

    BOOL composingTweet;
    NSString * directMessageRecipient;

    NSString * viewingUrl;
    NSString * viewingHtml;
}

@property (nonatomic, assign) NSUInteger selectedTab;
@property (nonatomic, assign) NSUInteger selectedTimelineFeed;
@property (nonatomic, copy) NSArray * tabOrder;

@property (nonatomic, assign) NSUInteger selectedSearchBookmarkIndex;
@property (nonatomic, assign) NSUInteger selectedPeopleBookmarkIndex;

@property (nonatomic, copy) NSString * findPeopleText;
@property (nonatomic, copy) NSString * searchText;

@property (nonatomic, assign) BOOL nearbySearch;

@property (nonatomic, assign) NSInteger numNewMentions;

@property (nonatomic, assign) BOOL composingTweet;
@property (nonatomic, copy) NSString * directMessageRecipient;

@property (nonatomic, copy) NSString * viewingUrl;
@property (nonatomic, copy) NSString * viewingHtml;

@end
