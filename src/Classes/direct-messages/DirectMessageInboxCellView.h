//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationPreview.h"

@interface DirectMessageInboxCellView : UIView
{
    ConversationPreview * preview;
	BOOL highlighted;
    BOOL landscape;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;

- (void)setConversationPreview:(ConversationPreview *)preview;

@end
