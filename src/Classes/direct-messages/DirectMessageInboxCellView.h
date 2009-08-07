//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationPreview.h"

@interface DirectMessageInboxCellView : UIView
{
    ConversationPreview * preview;
	BOOL highlighted;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

- (void)setConversationPreview:(ConversationPreview *)preview;

@end
