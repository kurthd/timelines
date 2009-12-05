//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
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
    NSString * cursor;
    NSNumber * page;  // only exists to give user class abstraction of pages
    NSString * queryTitle;
    CLLocation * nearbySearchLocation;
    NSNumber * updateId;

    id<TimelineDataSourceDelegate> dataSourceDelegate;
}

@property (nonatomic, retain) CLLocation * nearbySearchLocation;
@property (nonatomic, assign) id<TimelineDataSourceDelegate> dataSourceDelegate;

- (id)initWithTwitterService:(TwitterService *)aService;

#pragma mark Displaying search results

- (void)displaySearchResults:(NSString *)aQueryString
                   withTitle:(NSString *)aTitle;
- (void)clearDisplay;

@end
