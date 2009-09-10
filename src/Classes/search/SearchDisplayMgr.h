//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TwitterService.h"
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"

@interface SearchDisplayMgr :
    NSObject <TwitterServiceDelegate, TimelineDataSource>
{
    NetworkAwareViewController * networkAwareViewController;

    TwitterService * service;

    NSArray * searchResults;
    NSString * queryString;
    NSString * queryTitle;
    BOOL nearbySearch;
    NSNumber * updateId;

    id<TimelineDataSourceDelegate> dataSourceDelegate;
}

@property (nonatomic, assign) BOOL nearbySearch;
@property (nonatomic, assign) id<TimelineDataSourceDelegate> dataSourceDelegate;

- (id)initWithTwitterService:(TwitterService *)aService;

#pragma mark Displaying search results

- (void)displaySearchResults:(NSString *)aQueryString
                   withTitle:(NSString *)aTitle;
- (void)clearDisplay;

@end
