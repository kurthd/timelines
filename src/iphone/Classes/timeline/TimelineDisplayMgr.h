//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TimelineViewController.h"
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"
#import "TimelineViewControllerDelegate.h"
#import "TweetDetailsViewController.h"

@interface TimelineDisplayMgr :
    NSObject
    <TwitterServiceDelegate, TimelineViewControllerDelegate,
    TweetDetailsViewDelegate>
{
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;
    TweetDetailsViewController * tweetDetailsController;

    TwitterService * service;

    Tweet * selectedTweet;
    NSMutableDictionary * timeline;
    NSNumber * updateId;
    NSUInteger pagesShown;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;
@property (readonly) TweetDetailsViewController * tweetDetailsController;

@property (nonatomic, retain) Tweet * selectedTweet;
@property (nonatomic, copy) NSNumber * updateId;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(TwitterService *)service;

- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)replyToTweet;
- (void)refresh;

@end
