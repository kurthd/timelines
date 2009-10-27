//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MentionsAcctMgr.h"

@implementation MentionsAcctMgr

- (void)dealloc
{
    [displayMgr release];
    [newMentionCounts release];
    [super dealloc];
}

- (id)initWithMentionTimelineDisplayMgr:(MentionTimelineDisplayMgr *)aDisplayMgr
{
    if (self = [super init]) {
        displayMgr = [aDisplayMgr retain];
        newMentionCounts = [[NSMutableDictionary dictionary] retain];
    }

    return self;
}

- (void)processAccountChangeToUsername:(NSString *)toUsername
    fromUsername:(NSString *)fromUsername
{
    NSLog(@"Updating mention display manager from '%@' to '%@'", fromUsername,
        toUsername);

    // fromUsername is nil when changing from a deleted account
    if (fromUsername) {
        NSNumber * numNewMentions =
            [NSNumber numberWithInt:displayMgr.numNewMentions];
        [newMentionCounts setObject:numNewMentions forKey:fromUsername];
    }

    NSNumber * toNewMentionCount = [newMentionCounts objectForKey:toUsername];
    toNewMentionCount =
        toNewMentionCount ? toNewMentionCount : [NSNumber numberWithInt:0];
    displayMgr.numNewMentions = [toNewMentionCount intValue];
}

- (void)processAccountRemovedForUsername:(NSString *)username
{
    [newMentionCounts removeObjectForKey:username];
    if ([[newMentionCounts allKeys] count] == 0)
        displayMgr.numNewMentions = 0;
}

@end
