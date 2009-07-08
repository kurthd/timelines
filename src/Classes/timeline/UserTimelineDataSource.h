//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"
#import "TwitterServiceDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@interface UserTimelineDataSource :
    NSObject <TimelineDataSource, TwitterServiceDelegate>
{
    NSObject<TimelineDataSourceDelegate> * delegate;
    TwitterService * service;
    
    TwitterCredentials * credentials;
}

@property (nonatomic, assign) NSObject<TimelineDataSourceDelegate> * delegate;

- (id)initWithTwitterService:(TwitterService *)service;

@end
