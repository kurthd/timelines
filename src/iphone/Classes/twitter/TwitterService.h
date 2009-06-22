//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGTwitterEngineDelegate.h"
#import "TwitterCredentials.h"
#import "TwitterServiceDelegate.h"

@class MGTwitterEngine;

@interface TwitterService : NSObject <MGTwitterEngineDelegate>
{
    id<TwitterServiceDelegate> delegate;

    NSMutableDictionary * pendingRequests;

    TwitterCredentials * credentials;
    MGTwitterEngine * twitter;

    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;
@property (nonatomic, copy) TwitterCredentials * credentials;

#pragma mark Initialization

- (id)initWithTwitterCredentials:(TwitterCredentials *)someCredentials
                         context:(NSManagedObjectContext *)aContext;

#pragma mark Account

- (void)checkCredentials;

#pragma mark Timeline

- (void)fetchTimelineSinceUpdateId:(NSNumber *)updateId
                              page:(NSNumber *)page
                             count:(NSNumber *)count;

#pragma mark Direct messages

- (void)fetchDirectMessagesSinceId:(NSNumber *)updateId page:(NSNumber *)page;

@end
