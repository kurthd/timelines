//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TimelineViewController.h"
#import "TimelineDataSource.h"
#import "TimelineViewControllerDelegate.h"
#import "TimelineDataSourceDelegate.h"
#import "TweetDetailsViewController.h"
#import "TwitterCredentials.h"

@interface TimelineDisplayMgr :
    NSObject
    <TimelineDataSourceDelegate, TimelineViewControllerDelegate,
    TweetDetailsViewDelegate>
{
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;
    TweetDetailsViewController * tweetDetailsController;

    NSObject<TimelineDataSource> * service;

    Tweet * selectedTweet;
    User * user;
    NSMutableDictionary * timeline;
    NSNumber * updateId;
    NSUInteger pagesShown;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;
@property (readonly) TweetDetailsViewController * tweetDetailsController;

@property (nonatomic, retain) Tweet * selectedTweet;
@property (nonatomic, retain) User * user;
@property (nonatomic, copy) NSNumber * updateId;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(NSObject<TimelineDataSource> *)service;

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSMutableDictionary *)tweets page:(NSUInteger)page;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)replyToTweet;
- (void)refresh;

@end
