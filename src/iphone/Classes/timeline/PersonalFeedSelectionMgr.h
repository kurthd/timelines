//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDisplayMgr.h"
#import "AllTimelineDataSource.h"
#import "MessagesTimelineDataSource.h"
#import "MentionsTimelineDataSource.h"
#import "TwitterService.h"

@interface PersonalFeedSelectionMgr : NSObject
{
    TimelineDisplayMgr * timelineDisplayMgr;
    AllTimelineDataSource * allTimelineDataSource;
    MessagesTimelineDataSource * messagesTimelineDataSource;
    MentionsTimelineDataSource * mentionsTimelineDataSource;

    NSDictionary * allTimelineTweets;
    NSUInteger allTimelinePagesShown;
    BOOL allTimelineRefresh;

    NSDictionary * messagesTimelineTweets;
    NSUInteger messagesTimelinePagesShown;
    BOOL messagesTimelineRefresh;

    NSDictionary * mentionsTimelineTweets;
    NSUInteger mentionsTimelinePagesShown;
    BOOL mentionsTimelineRefresh;

    NSInteger previousTab;
}

@property (nonatomic, copy) NSDictionary * allTimelineTweets;
@property (nonatomic, copy) NSDictionary * mentionsTimelineTweets;
@property (nonatomic, copy) NSDictionary * messagesTimelineTweets;

- (id)initWithTimelineDisplayMgr:(TimelineDisplayMgr *)timelineDisplayMgr
    allService:(TwitterService *)allService
    mentionsService:(TwitterService *)mentionsService
    messagesService:(TwitterService *)messagesService;

- (void)tabSelected:(id)sender;

@end
