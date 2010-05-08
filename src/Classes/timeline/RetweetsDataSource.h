//
//  Copyright 2010 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"
#import "TwitterServiceDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@interface RetweetsDataSource :
    NSObject <TimelineDataSource, TwitterServiceDelegate>
{
    NSObject<TimelineDataSourceDelegate> * delegate;
    TwitterService * service;
}

@property (nonatomic, assign) NSObject<TimelineDataSourceDelegate> * delegate;

- (id)initWithTwitterService:(TwitterService *)service;

@end
