//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"
#import "TwitterServiceDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@interface MyFavoritesTimelineDataSource :
    NSObject <TimelineDataSource, TwitterServiceDelegate>
{
    NSObject<TimelineDataSourceDelegate> * delegate;
    TwitterService * service;
    NSString * username;
}

@property (nonatomic, assign) NSObject<TimelineDataSourceDelegate> * delegate;
@property (nonatomic, copy) NSString * username;

- (id)initWithTwitterService:(TwitterService *)service;

@end
