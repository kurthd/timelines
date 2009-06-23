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
#import "TweetInfo.h"

@interface TimelineDisplayMgr :
    NSObject
    <TimelineDataSourceDelegate, TimelineViewControllerDelegate,
    TweetDetailsViewDelegate>
{
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;
    TweetDetailsViewController * tweetDetailsController;

    NSObject<TimelineDataSource> * service;

    TweetInfo * selectedTweet;
    User * user;
    NSMutableDictionary * timeline;
    NSNumber * updateId;
    NSUInteger pagesShown;
    
    TwitterCredentials * credentials;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;
@property (readonly) TweetDetailsViewController * tweetDetailsController;

@property (nonatomic, retain) TweetInfo * selectedTweet;
@property (nonatomic, retain) User * user;
@property (nonatomic, copy) NSNumber * updateId;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(NSObject<TimelineDataSource> *)service;

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)tweets page:(NSUInteger)page;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)replyToTweet;
- (void)refresh;

- (void)addTweet:(Tweet *)tweet;

@end
