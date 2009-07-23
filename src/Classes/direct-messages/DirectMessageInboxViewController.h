//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessageInboxViewControllerDelegate.h"

@interface DirectMessageInboxViewController : UITableViewController
{
    IBOutlet UIButton * loadMoreButton;
    IBOutlet UILabel * numMessagesLabel;
    IBOutlet UIView * footerView;

    NSObject<DirectMessageInboxViewControllerDelegate> * delegate;
    NSArray * conversationPreviews;
}

@property (nonatomic, assign)
    NSObject<DirectMessageInboxViewControllerDelegate> * delegate;

- (IBAction)loadMoreDirectMessages:(id)sender;

- (void)setConversationPreviews:(NSArray *)conversationPreviews;
- (void)setNumReceivedMessages:(NSUInteger)receivedMessages
    sentMessages:(NSUInteger)sentMessages;

@end
