//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "SearchViewController.h"
#import "TwitterService.h"
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"

@interface SearchDisplayMgr :
    NSObject <SearchViewControllerDelegate, TwitterServiceDelegate,
    TimelineDataSource>
{
    NetworkAwareViewController * networkAwareViewController;
    SearchViewController * searchViewController;

    TwitterService * service;

    NSArray * searchResults;
    NSString * queryString;
    NSString * queryTitle;
    NSNumber * updateId;

    id<TimelineDataSourceDelegate> dataSourceDelegate;
}

@property (nonatomic, assign) id<TimelineDataSourceDelegate> dataSourceDelegate;

- (id)initWithTwitterService:(TwitterService *)aService;

#pragma mark Displaying search results

- (void)displaySearchResults:(NSString *)aQueryString
                   withTitle:(NSString *)aTitle;

@end
