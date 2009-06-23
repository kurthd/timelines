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
    TwitterService * service;

    NSDictionary * allTimelineTweets;
    NSUInteger allTimelinePagesShown;

    NSDictionary * messagesTimelineTweets;
    NSUInteger messagesTimelinePagesShown;

    NSDictionary * mentionsTimelineTweets;
    NSUInteger mentionsTimelinePagesShown;

    NSInteger previousTab;
}

@property (nonatomic, copy) NSDictionary * allTimelineTweets;
@property (nonatomic, copy) NSDictionary * mentionsTimelineTweets;
@property (nonatomic, copy) NSDictionary * messagesTimelineTweets;

- (id)initWithTimelineDisplayMgr:(TimelineDisplayMgr *)timelineDisplayMgr
    service:(TwitterService *)service;

- (void)tabSelected:(id)sender;

@end
