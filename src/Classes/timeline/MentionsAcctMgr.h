//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MentionTimelineDisplayMgr.h"

@interface MentionsAcctMgr : NSObject
{
    MentionTimelineDisplayMgr * displayMgr;
}

- (id)initWithMentionTimelineDisplayMgr:(MentionTimelineDisplayMgr *)displayMgr;

- (void)processAccountChangeToUsername:(NSString *)toUsername
    fromUsername:(NSString *)fromUsername;
- (void)processAccountRemovedForUsername:(NSString *)username;

@end
