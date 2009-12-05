//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"
#import "TwitterServiceDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@interface SearchDataSource :
    NSObject <TimelineDataSource, TwitterServiceDelegate>
{
    NSObject<TimelineDataSourceDelegate> * delegate;
    TwitterService * service;
    NSString * query;
    NSString * cursor;
    NSNumber * page;
}

@property (nonatomic, assign) NSObject<TimelineDataSourceDelegate> * delegate;
@property (nonatomic, copy) NSString * query;

- (id)initWithTwitterService:(TwitterService *)service
    query:(NSString *)query;

@end
