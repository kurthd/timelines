//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MentionsAcctMgr.h"

@implementation MentionsAcctMgr

- (void)dealloc
{
    [displayMgr release];
    [super dealloc];
}

- (id)initWithMentionTimelineDisplayMgr:(MentionTimelineDisplayMgr *)aDisplayMgr
{
    if (self = [super init])
        displayMgr = [aDisplayMgr retain];
    
    return self;
}

- (void)processAccountChangeToUsername:(NSString *)toUsername
    fromUsername:(NSString *)fromUsername
{
    NSLog(@"Updating mention display manager from '%@' to '%@'", fromUsername,
        toUsername);
}

- (void)processAccountRemovedForUsername:(NSString *)username
{
    [displayMgr clearState];
}

@end
