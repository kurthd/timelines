//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessageInboxViewControllerDelegate.h"

@interface DirectMessageInboxViewController : UITableViewController
{
    NSObject<DirectMessageInboxViewControllerDelegate> * delegate;
    NSArray * conversationPreviews;
}

@property (nonatomic, assign)
    NSObject<DirectMessageInboxViewControllerDelegate> * delegate;

- (void)setConversationPreviews:(NSArray *)conversationPreviews;

@end
