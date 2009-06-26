//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"
#import "TwitterServiceDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@interface MessagesTimelineDataSource :
    NSObject <TimelineDataSource, TwitterServiceDelegate>
{
    NSObject<TimelineDataSourceDelegate> * delegate;
    TwitterService * service;
    
    NSArray * incomingMessages;
    NSInteger outstandingIncomingMessages;

    NSArray * outgoingMessages;
    NSInteger outstandingOutgoingMessages;
}

@property (nonatomic, assign) NSObject<TimelineDataSourceDelegate> * delegate;

@property (nonatomic, copy) NSArray * incomingMessages;
@property (nonatomic, copy) NSArray * outgoingMessages;

- (id)initWithTwitterService:(TwitterService *)service;

@end
