//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationPreview.h"

@protocol DirectMessageInboxViewControllerDelegate

- (void)selectedConversationPreview:(ConversationPreview *)preview;

@end
