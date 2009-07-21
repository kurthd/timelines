//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationPreview.h"

@interface DirectMessageInboxCell : UITableViewCell
{
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * dateLabel;
    IBOutlet UILabel * messagePreviewLabel;
    IBOutlet UIView * newMessagesView;
}

- (void)setConversationPreview:(ConversationPreview *)preview;

@end
