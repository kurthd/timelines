//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageInboxCell.h"
#import "NSDate+StringHelpers.h"
#import "UILabel+DrawingAdditions.h"

@implementation DirectMessageInboxCell

- (void)dealloc
{
    [nameLabel release];
    [dateLabel release];
    [messagePreviewLabel release];
    [newMessagesView release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat messagePreviewHeight =
        [messagePreviewLabel heightForString:messagePreviewLabel.text];
    messagePreviewHeight =
        messagePreviewHeight > 34 ? 34 : messagePreviewHeight;
    CGRect messagePreviewLabelFrame = messagePreviewLabel.frame;
    messagePreviewLabelFrame.size.height = messagePreviewHeight;
    messagePreviewLabel.frame = messagePreviewLabelFrame;
}

- (void)setConversationPreview:(ConversationPreview *)preview
{
    nameLabel.text = preview.otherUserName;
    dateLabel.text = [preview.mostRecentMessageDate shortDescription];
    messagePreviewLabel.text = preview.mostRecentMessage;
    newMessagesView.hidden = !preview.newMessages;
}

@end
