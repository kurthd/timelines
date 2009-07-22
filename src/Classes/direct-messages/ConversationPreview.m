//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ConversationPreview.h"

@implementation ConversationPreview

@synthesize otherUserId, otherUserName, mostRecentMessage,
    mostRecentMessageDate, numNewMessages;

- (void)dealloc
{
    [otherUserId release];
    [otherUserName release];
    [mostRecentMessage release];
    [mostRecentMessageDate release];
    [super dealloc];
}

- (id)initWithOtherUserId:(id)anotherUserId
    otherUserName:(NSString *)anotherUserName
    mostRecentMessage:(NSString *)aMostRecentMessage
    mostRecentMessageDate:(NSDate *)aMostRecentMessageDate
    numNewMessages:(NSUInteger)numNewMessagesVal
{
    if (self = [super init]) {
        otherUserId = [anotherUserId copy];
        otherUserName = [anotherUserName copy];
        mostRecentMessage = [aMostRecentMessage copy];
        mostRecentMessageDate = [aMostRecentMessageDate retain];
        numNewMessages = numNewMessagesVal;
    }

    return self;
}

- (id)copy {
    return [self retain]; // immutable
}

- (NSComparisonResult)compare:(ConversationPreview *)preview
{
    return [preview.mostRecentMessageDate compare:self.mostRecentMessageDate];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{%@, %@, %@, %@}", otherUserId,
        otherUserName, mostRecentMessage, mostRecentMessageDate];
}

@end
