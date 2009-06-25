//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@protocol TimelineDataSourceDelegate

- (void)timeline:(NSArray *)aTimeline
    fetchedSinceUpdateId:(NSNumber *)anUpdateId page:(NSNumber *)page;
- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error;

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)username;
- (void)failedToFetchUserInfoForUsername:(NSString *)username
                                   error:(NSError *)error;

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)username
          page:(NSNumber *)page;

- (void)failedToFetchFriendsForUsername:(NSString *)username
                                  page:(NSNumber *)page
                                 error:(NSError *)error;

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)username
            page:(NSNumber *)page;
- (void)failedToFetchFollowersForUsername:(NSString *)username
                                    page:(NSNumber *)page
                                   error:(NSError *)error;
@end
