//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationPreview.h"
#import "DirectMessageInboxCellView.h"

@interface DirectMessageInboxCell : UITableViewCell
{
    DirectMessageInboxCellView * cellView;
}

@property (nonatomic, retain) DirectMessageInboxCellView * cellView;

- (void)setConversationPreview:(ConversationPreview *)preview;

- (void)redisplay;

@end
