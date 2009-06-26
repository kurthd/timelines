//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterService.h"
#import "SearchBarViewController.h"
#import "NetworkAwareViewController.h"
#import "SearchDisplayMgr.h"
#import "TimelineDisplayMgr.h"
#import "CredentialsActivatedPublisher.h"

@interface SearchBarDisplayMgr : NSObject
    <TwitterServiceDelegate, /*NetworkAwareViewControllerDelegate,*/
    SearchBarViewControllerDelegate, UISearchBarDelegate>
{
    TwitterService * service;

    NetworkAwareViewController * networkAwareViewController;
    UISearchBar * searchBar;

    TimelineDisplayMgr * timelineDisplayMgr;
    SearchDisplayMgr * searchDisplayMgr;

    NSArray * searchResults;
    NSString * searchQuery;
    NSNumber * searchPage;

    id<TimelineDataSourceDelegate> dataSourceDelegate;

    CredentialsActivatedPublisher * credentialsActivatedPublisher;
}

@property (nonatomic, assign) id<TimelineDataSourceDelegate> dataSourceDelegate;

- (id)initWithTwitterService:(TwitterService *)aService
          netAwareController:(NetworkAwareViewController *)navc
          timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
